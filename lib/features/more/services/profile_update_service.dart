import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../app/urls.dart';
import '../../../core/services/token_validation_service.dart';

class ProfileUpdateService {
  static Future<bool> updateProfile({
    required String name,
    XFile? profileImageFile,
  }) async {
    try {
      print('=== PROFILE UPDATE SERVICE START (PATCH) ===');
      print('Name: $name');
      print('Profile Image File: ${profileImageFile?.path}');

      final token = await TokenValidationService.getValidToken();
      if (token == null) {
        print('❌ No valid token found');
        return false;
      }

      print('✅ Valid token found: ${token.substring(0, math.min(20, token.length))}...');

      // Use MultipartRequest for PATCH
      var request = http.MultipartRequest('PATCH', Uri.parse(Urls.Self_Profile_Update));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        // 'Content-Type': 'multipart/form-data', // http package adds this automatically for MultipartRequest
      });

      // Add fields
      request.fields['name'] = name;

      // Add file if provided
      if (profileImageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          profileImageFile.path,
          filename: profileImageFile.name,
        ));
        print('📦 Attached file: ${profileImageFile.name}');
      }

      print('📤 Sending PATCH request to: ${Urls.Self_Profile_Update}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 API Response:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Profile updated successfully');
        return true;
      } else {
        print('❌ Profile update failed');
        print('   - Status: ${response.statusCode}');
        print('   - Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('💥 Error: $e');
      return false;
    }
  }
}
