import '../../../app/urls.dart';

class UserProfileModel {
  final String name;
  final String email;
  final String? profileImage;
  final String role;

  UserProfileModel({
    required this.name,
    required this.email,
    this.profileImage,
    required this.role,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['profile_image'] ?? json['image'] ?? json['avatar'];

    // Add base URL if the image URL is relative
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = '${Urls.baseUrl}$imageUrl';
    }

    print('🔍 Profile Image URL Processing:');
    print(
      '   - Original: ${json['profile_image'] ?? json['image'] ?? json['avatar']}',
    );
    print('   - Processed: $imageUrl');

    return UserProfileModel(
      name: json['name'] ?? json['username'] ?? json['first_name'] ?? 'User',
      email: json['email'] ?? '',
      profileImage: imageUrl,
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'role': role,
    };
  }
}
