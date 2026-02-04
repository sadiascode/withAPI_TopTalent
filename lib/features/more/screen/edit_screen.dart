import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:top_talent_agency/common/custom_button.dart';
import 'package:top_talent_agency/core/roles.dart';
import 'package:top_talent_agency/features/more/widget/custom_align.dart';
import 'package:top_talent_agency/features/more/services/password_change_service.dart';
import 'package:top_talent_agency/features/more/services/profile_update_service.dart';
import 'package:top_talent_agency/features/more/services/user_profile_service.dart';
import 'package:top_talent_agency/features/more/data/user_profile_model.dart';
import 'package:top_talent_agency/app/urls.dart';
import 'package:top_talent_agency/core/services/token_validation_service.dart';

import '../../auth/ui/widgets/custom_textfield.dart';

class EditScreen extends StatefulWidget {
  final UiUserRole role;

  EditScreen({super.key, required this.role});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  UserProfileModel? userProfile;
  bool isLoadingProfile = true;
  XFile? selectedImage;
  bool isUploadingImage = false;

  bool get isAdmin => widget.role == UiUserRole.admin;
  bool get isManager => widget.role == UiUserRole.manager;
  bool get isCreator => widget.role == UiUserRole.creator;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await UserProfileService.getUserProfile();
      if (mounted) {
        setState(() {
          userProfile = profile;
          emailController.text = profile?.email ?? '';
          nameController.text = profile?.name ?? '';
          isLoadingProfile = false;
        });
        print('✅ User profile loaded: ${profile?.email}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
        });
      }
      print('❌ Error loading user profile: $e');
    }
  }

  // Image upload method
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      print('=== UPLOADING IMAGE ===');
      print('Image path: ${imageFile.path}');

      final token = await TokenValidationService.getValidToken();
      if (token == null) {
        print('❌ No valid token found');
        return null;
      }

      final dio = Dio();

      FormData formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        ),
      });

      final response = await dio.post(
        Urls.Self_Profile_Update,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('📤 Image Upload Response:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // Extract the image URL from the response
        final responseData = response.data as Map<String, dynamic>;
        String? profileImageUrl;

        // Check different possible response formats
        if (responseData['profile_image'] != null) {
          profileImageUrl = responseData['profile_image'] as String?;
        } else if (responseData['data'] != null &&
            responseData['data']['profile_image'] != null) {
          profileImageUrl = responseData['data']['profile_image'] as String?;
        } else if (responseData['user'] != null &&
            responseData['user']['profile_image'] != null) {
          profileImageUrl = responseData['user']['profile_image'] as String?;
        }

        // Add base URL if the image URL is relative
        if (profileImageUrl != null && !profileImageUrl.startsWith('http')) {
          profileImageUrl = '${Urls.baseUrl}$profileImageUrl';
        }

        if (profileImageUrl != null) {
          print('✅ Image uploaded successfully: $profileImageUrl');
          return profileImageUrl;
        }
      }

      print('❌ Image upload failed');
      return null;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  // Password change method
  Future<void> changePassword(BuildContext context) async {
    if (oldPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Please fill all password fields',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );

      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'New password and confirm password do not match',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
      return;
    }

    final success = await PasswordChangeService.changePassword(
      oldPassword: oldPasswordController.text,
      newPassword: newPasswordController.text,
      confirmPassword: confirmPasswordController.text,
      role: widget.role,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Password changed successfully',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
      // Clear password fields
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Password change failed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
  }

  // Profile update method
  Future<void> updateProfile(BuildContext context) async {
    print('=== PROFILE UPDATE METHOD START ===');
    print('Name Controller Text: "${nameController.text}"');
    print('Name Length: ${nameController.text.length}');

    if (nameController.text.isEmpty) {
      print('❌ Validation Failed: Name is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Please enter your name',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
      return;
    }

    print('✅ Validation Passed: Calling ProfileUpdateService');
    final success = await ProfileUpdateService.updateProfile(
      name: nameController.text,
      profileImage: null, // Can add image picker later
    );

    print('ProfileUpdateService Result: $success');
    if (success) {
      print('✅ Profile Update Success - Showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Profile updated successfully',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
    } else {
      print('❌ Profile Update Failed - Showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Profile update failed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
    print('=== PROFILE UPDATE METHOD END ===');
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
        title: Text(
          widget.role == UiUserRole.admin
              ? 'Edit Admin'
              : widget.role == UiUserRole.manager
              ? 'Edit Manager'
              : 'Edit Creator',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.40,
                    height: MediaQuery.of(context).size.width * 0.40,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: selectedImage != null
                          ? Image.file(
                              File(selectedImage!.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 150,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : userProfile?.profileImage != null
                          ? Image.network(
                              userProfile!.profileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 150,
                                  color: Colors.grey,
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.person,
                                size: 150,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ),
                if (isUploadingImage)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.40,
                    height: MediaQuery.of(context).size.width * 0.40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            GestureDetector(
              onTap: () async {
                final ImagePicker picker = ImagePicker();
                // Pick an image.
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );

                if (image != null) {
                  setState(() {
                    selectedImage = image;
                    isUploadingImage = true;
                  });

                  // Upload the image
                  final imageUrl = await uploadImage(image);

                  if (mounted) {
                    setState(() {
                      isUploadingImage = false;
                    });

                    if (imageUrl != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.black,
                          content: Text(
                            'Profile image updated successfully',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                      // Refresh profile to show new image
                      _fetchUserProfile();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.black,
                          content: Text(
                            'Failed to update profile image',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(
                'Change photo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 30),
            CustomAlign(title: "Name"),
            const SizedBox(height: 5),
            CustomTextfield(
              controller: nameController,
              textColor: Colors.white,
            ),

            const SizedBox(height: 20),
            CustomAlign(title: "Email ID"),
            const SizedBox(height: 5),
            isLoadingProfile
                ? Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : CustomTextfield(
                    controller: emailController,
                    textColor: Colors.white,
                    readOnly: true, // Email cannot be edited
                  ),

            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Old Password',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Change password',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                CustomTextfield(
                  controller: oldPasswordController,
                  hintText: "Enter Your Old Password",
                  isPassword: true,
                  textColor: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Password',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Change password',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                CustomTextfield(
                  controller: newPasswordController,
                  hintText: "Enter Your New Password",
                  isPassword: true,
                  textColor: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confirm Password',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Change password',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                CustomTextfield(
                  controller: confirmPasswordController,
                  hintText: "Confirm Your New Password",
                  isPassword: true,
                  textColor: Colors.white,
                ),
              ],
            ),
            SizedBox(height: 30),
            CustomButton(
              text: "Save Changes",
              onTap: () async {
                print('=== SAVE BUTTON CLICKED ===');

                // Check if any password fields are filled
                bool hasPasswordData =
                    oldPasswordController.text.isNotEmpty ||
                    newPasswordController.text.isNotEmpty ||
                    confirmPasswordController.text.isNotEmpty;

                bool hasProfileData = nameController.text.isNotEmpty;

                print('Save Button Analysis:');
                print('   - Has Password Data: $hasPasswordData');
                print('   - Has Profile Data: $hasProfileData');
                print('   - Name Text: "${nameController.text}"');
                print(
                  '   - Old Password Length: ${oldPasswordController.text.length}',
                );
                print(
                  '   - New Password Length: ${newPasswordController.text.length}',
                );
                print(
                  '   - Confirm Password Length: ${confirmPasswordController.text.length}',
                );

                if (hasPasswordData && hasProfileData) {
                  print(
                    '🔄 Scenario: Both profile and password changes detected',
                  );
                  // Update both profile and password
                  await updateProfile(context);
                  await changePassword(context);
                } else if (hasPasswordData) {
                  print('🔄 Scenario: Only password change detected');
                  // Only change password
                  await changePassword(context);
                } else if (hasProfileData) {
                  print('🔄 Scenario: Only profile change detected');
                  // Only update profile
                  await updateProfile(context);
                } else {
                  print('🔄 Scenario: No changes detected');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.black,
                      content: Text(
                        'No changes to save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                print('=== SAVE BUTTON COMPLETE ===');
              },
            ),
          ],
        ),
      ),
    );
  }
}
