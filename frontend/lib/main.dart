import 'package:flutter/material.dart';
import 'package:MediSafe/screens/authService/login.dart';
import 'package:MediSafe/screens/authService/register.dart';
import 'package:MediSafe/screens/dashboard/dashboard.dart';
import 'package:MediSafe/screens/profile/profileScreen.dart';
import 'package:MediSafe/screens/userFeel/feel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  runApp(MyApp(isLoggedIn: token != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => Dashboard(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
