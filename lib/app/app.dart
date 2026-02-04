import 'package:flutter/material.dart';
import '../features/auth/ui/screens/login_screen.dart';
import '../common/app_shell.dart';
import '../core/services/token_storage_service.dart';
import '../core/services/role_storage_service.dart';

class TopTalentAgency extends StatelessWidget {
  const TopTalentAgency({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Top Talent Agency",
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: TokenStorageService.hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (snapshot.data == true) {
            final role = RoleStorageService.getRole();
            return AppShell(role: role);
          }

          return LoginScreen();
        },
      ),
    );
  }
}
