import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'services/notification_service.dart';
import 'pages/navbar.dart';
import 'services/secure_store.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  tz.initializeTimeZones();

  runApp(const ParuGuardApp());
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<String?> _checkSession() async {
    return await SecureStore.readEncrypted('session_user');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const Navbar();
        }
        return const LoginPage();
      },
    );
  }
}

class ParuGuardApp extends StatelessWidget {
  const ParuGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParuGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
