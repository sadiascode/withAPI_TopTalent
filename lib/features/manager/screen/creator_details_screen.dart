import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:top_talent_agency/features/home/widget/custom_pichart.dart';
import 'package:top_talent_agency/features/manager/widget/ai_analysis_card.dart';
import 'package:top_talent_agency/features/manager/widget/live_chart.dart';
import 'package:top_talent_agency/features/manager/widget/profile_card.dart';
import 'package:top_talent_agency/features/manager/widget/progress_card.dart';
import 'package:top_talent_agency/features/manager/data/single_creator_model.dart';
import 'package:top_talent_agency/features/manager/data/analysis_model.dart';
import 'package:top_talent_agency/app/urls.dart';
import 'package:top_talent_agency/core/services/token_storage_service.dart';

import '../../../common/custom_color.dart';

class CreatorDetailsScreen extends StatefulWidget {
  final int? creatorId;

  const CreatorDetailsScreen({super.key, this.creatorId});

  @override
  State<CreatorDetailsScreen> createState() => _CreatorDetailsScreenState();
}

class _CreatorDetailsScreenState extends State<CreatorDetailsScreen> {
  bool isLoading = false;
  SingleCreatorModel? creatorInfo;
  AnalysisModel? analysisData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.creatorId != null) {
      _fetchCreatorDetails();
      _fetchAIAnalysis();
    }
  }

  Future<void> _fetchCreatorDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await TokenStorageService.getStoredToken();
      final dio = Dio();

      final response = await dio.get(
        Urls.singleCreatorDashboardScore(widget.creatorId!),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('🔍 Creator Details API Response: $data');

        SingleCreatorModel creator;
        if (data is List && data.isNotEmpty) {
          creator = SingleCreatorModel.fromJson(data[0]);
        } else if (data is Map<String, dynamic>) {
          creator = SingleCreatorModel.fromJson(data);
        } else {
          throw Exception('Invalid response format');
        }

        setState(() {
          creatorInfo = creator;
          isLoading = false;
        });

        print('✅ Creator Details Parsed: ${creator.username}');
      } else {
        setState(() {
          errorMessage =
              'Failed to load creator details (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
      print('❌ Error fetching creator details: $e');
    }
  }

  Future<void> _fetchAIAnalysis() async {
    try {
      final token = await TokenStorageService.getStoredToken();
      final dio = Dio();

      // Fetch AI analysis for creator role with specific creator ID
      final response = await dio.get(
        Urls.AI_Response_admin_manager_creator,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('🔍 AI Analysis API Response for Creator: $data');

        // Parse the response to find analysis for this specific creator
        if (data is List) {
          print('🔍 AI Analysis List Length: ${data.length}');
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              print('🔍 Processing AI Analysis Item: $item');
              // Check if this analysis is for the current creator
              final userId = item['user_id'];
              final role = item['role'];

              print(
                '🔍 Looking for Creator ID: ${widget.creatorId}, Role: CREATOR',
              );
              print('🔍 Found User ID: $userId, Role: $role');

              if (userId == widget.creatorId && role == 'CREATOR') {
                final analysis = AnalysisModel(
                  summary: item['alert_message'] ?? 'No analysis available',
                  reason: item['reason'] ?? '',
                );

                setState(() {
                  analysisData = analysis;
                });

                print('✅ Creator AI Analysis found: ${analysis.summary}');
                return;
              }
            }
          }
        } else if (data is Map<String, dynamic>) {
          print(
            '🔍 AI Analysis is a Map, checking keys: ${data.keys.toList()}',
          );

          // Extract data from daily_summary
          final dailySummary = data['daily_summary'] as Map<String, dynamic>?;
          if (dailySummary != null) {
            final summary = dailySummary['summary'] as String?;
            final reason = dailySummary['reason'] as String?;

            if (summary != null) {
              final analysis = AnalysisModel(
                summary: summary,
                reason: reason ?? '',
              );

              setState(() {
                analysisData = analysis;
              });

              print(
                '✅ Creator AI Analysis found (from daily_summary): ${analysis.summary}',
              );
              return;
            }
          }

          // Fallback to welcome_msg if no daily_summary
          final welcomeMsg = data['welcome_msg'] as Map<String, dynamic>?;
          if (welcomeMsg != null) {
            final msg = welcomeMsg['msg'] as String?;
            if (msg != null) {
              final analysis = AnalysisModel(summary: msg, reason: '');

              setState(() {
                analysisData = analysis;
              });

              print(
                '✅ Creator AI Analysis found (from welcome_msg): ${analysis.summary}',
              );
              return;
            }
          }
        }

        print('⚠️ No AI analysis found for this creator');
      }
    } catch (e) {
      print('❌ Error fetching AI analysis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        title: const Text(
          "Creator Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show loading indicator
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Show error message
            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B1B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchCreatorDetails,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Show content if not loading
            if (!isLoading) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff0B1220), Color(0xff1A2A3A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ProfileCard(creatorInfo: creatorInfo),
              ),

              const SizedBox(height: 14),
              const Text(
                "Monthly Overview",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              CustomPichart(
                diamondValue: creatorInfo?.totalDiamond?.toString() ?? '0',
              ),

              const SizedBox(height: 16),
              AiAnalysisCard(analysisData: analysisData),

              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xff101828),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Target vs Actual (Current Month)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ProgressCard(
                          subtitle:
                              creatorInfo?.totalDiamond?.toString() ?? '0',
                          title: "Coins",
                          percent: 1.2,
                        ),

                        const SizedBox(height: 10),

                        ProgressCard(
                          subtitle: creatorInfo?.totalHour?.toString() ?? '0',
                          title: "Hours",
                          percent: 1.144,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LiveChart(
                monthlyData: creatorInfo?.last3Months.months.map(
                  (key, value) => MapEntry(key, value.diamonds.toDouble()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
