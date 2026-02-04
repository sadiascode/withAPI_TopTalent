import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:top_talent_agency/core/roles.dart';
import 'package:top_talent_agency/app/urls.dart';
import 'package:top_talent_agency/core/services/token_storage_service.dart';
import 'package:top_talent_agency/features/target/data/target_request_model.dart';
import '../widget/custom_targets.dart';

class TargetsScreen extends StatefulWidget {
  final UiUserRole role;
  const TargetsScreen({super.key, required this.role});

  @override
  State<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends State<TargetsScreen> {
  bool isLoading = true;
  final List<_MonthTarget> monthTargets = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print('🎯 TARGETS SCREEN INIT - Role: ${widget.role}');
    _fetchTargetData();
  }

  Future<void> _fetchTargetData() async {
    print('=== TARGETS SCREEN: FETCHING DATA ===');
    try {
      final dio = Dio();

      // Get authentication token
      final token = await TokenStorageService.getStoredToken();
      print('   - Token found: ${token != null ? "YES" : "NO"}');

      if (!mounted) return;
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final apiUrl = _roleWiseMonthUrl(widget.role, "");
      print(' Target Request:');
      print('   - Role: ${widget.role}');
      print('   - URL: $apiUrl');

      try {
        final response = await dio.get(
          apiUrl,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          print('🔍 Raw API Response:');
          print('   - Status: ${response.statusCode}');
          print('   - Data type: ${response.data.runtimeType}');
          print('   - Full response: ${response.data}');

          Map<String, dynamic> data;
          if (response.data is Map) {
            data = (response.data as Map).cast<String, dynamic>();
          } else if (response.data is List && response.data.isNotEmpty) {
            // Handle List response (manager/creator structure)
            final listData = response.data as List;
            print('   - Response is List with ${listData.length} items');
            if (listData.first is Map) {
              data = Map<String, dynamic>.from(listData.first);
              print('   - Using first item from List: ${data.keys.toList()}');
            } else {
              print('   - List item is not a Map, using empty map');
              data = {};
            }
          } else {
            print('   - Unexpected response format, using empty map');
            data = {};
          }

          print('   - Processed data keys: ${data.keys.toList()}');

          // Extract data based on different API response structures
          final List<_MonthTarget> fetched = [];

          // Try to get last_3_months data (admin structure)
          final last3Months = data['last_3_months'] as Map<String, dynamic>?;
          print('   - last3Months type: ${last3Months.runtimeType}');
          print('   - last3Months value: $last3Months');

          if (last3Months != null) {
            print(
              '   - Found last_3_months data with ${last3Months.length} entries',
            );
            last3Months.forEach((monthName, monthData) {
              print('   - Processing month: $monthName, data: $monthData');
              if (monthData is Map<String, dynamic>) {
                final targetModel = TargetRequestModel.fromJson(monthData);
                print(
                  '   - Created targetModel: ${targetModel.diamonds} diamonds, ${targetModel.hours} hours',
                );
                fetched.add(
                  _MonthTarget(
                    month: monthName,
                    data: monthData,
                    targetModel: targetModel,
                  ),
                );
              }
            });
            print('   - Total fetched items: ${fetched.length}');
          } else {
            print('   - No last_3_months found, trying other structures');
            // Try direct data structure (manager/creator structure)

            // Check if the main data has diamonds and hours
            if (data.containsKey('diamonds') ||
                data.containsKey('total_diamond_achieve') ||
                data.containsKey('target_diamonds')) {
              final targetModel = TargetRequestModel.fromJson(data);
              fetched.add(
                _MonthTarget(
                  month: 'Current Month',
                  data: data,
                  targetModel: targetModel,
                ),
              );
            } else {
              // Try to get individual month data if available
              final months = ['February', 'January', 'December'];
              for (final month in months) {
                if (data.containsKey(month.toLowerCase())) {
                  final monthData = data[month.toLowerCase()];
                  if (monthData is Map<String, dynamic>) {
                    final targetModel = TargetRequestModel.fromJson(monthData);
                    fetched.add(
                      _MonthTarget(
                        month: month,
                        data: monthData,
                        targetModel: targetModel,
                      ),
                    );
                  }
                }
              }
            }
          }

          print('   - Final fetched count: ${fetched.length}');
          if (fetched.isEmpty) {
            print('   - No valid data found in any structure');
            if (!mounted) return;
            setState(() {
              isLoading = false;
              errorMessage = 'No monthly data found in API response';
            });
          } else {
            print('   - Setting state with ${fetched.length} items');
            if (!mounted) return;
            setState(() {
              monthTargets
                ..clear()
                ..addAll(fetched);
              isLoading = false;
            });
          }
        } else {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            errorMessage = 'Request failed (${response.statusCode})';
          });
        }
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = 'Request failed (${status ?? 'no status'})';
        });
      }
    } catch (e) {
      print('❌ Error fetching target data: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🎯 BUILD METHOD - isLoading: $isLoading, monthTargets.length: ${monthTargets.length}, errorMessage: $errorMessage',
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.role == UiUserRole.creator
              ? "Targets for you"
              : "Total targets for Agency",
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (monthTargets.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xff1D0014),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.data_usage,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No target data available",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorMessage ??
                                  "Please check your connection and try again",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchTargetData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff620041),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ...monthTargets.map((item) {
                        print('🎯 BUILDING CustomTargets for ${item.month}:');
                        print('   - diamonds: ${item.targetModel?.diamonds}');
                        print('   - hours: ${item.targetModel?.hours}');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: CustomTargets(
                            title:
                                item.data['month']?.toString() ??
                                _formatMonthLabel(item.month),
                            progressBarColor: Colors.blue,
                            containerColor: const Color(0xff1D0014),
                            diamonds: item.targetModel?.diamonds ?? 0,
                            Hours: item.targetModel?.hours ?? 0.0,
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return const Color(0xff00A63E); // Green
    if (percentage >= 0.8) return Colors.orange;
    if (percentage >= 0.6) return Colors.yellow;
    return Colors.red;
  }
}

String _roleWiseMonthUrl(UiUserRole role, String month) {
  switch (role) {
    case UiUserRole.admin:
      return Urls.Admin;
    case UiUserRole.creator:
      return Urls.Creator_Dashboard_Score;
    case UiUserRole.manager:
    default:
      return Urls.Manager_Dashboard_Score;
  }
}

class _MonthTarget {
  final String month;
  final Map<String, dynamic> data;
  final TargetRequestModel? targetModel;

  const _MonthTarget({
    required this.month,
    required this.data,
    this.targetModel,
  });
}

String _formatMonthLabel(String monthName) {
  // The API already provides readable month names like "February", "January", etc.
  return monthName;
}
