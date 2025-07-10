import 'package:flutter/material.dart';
import 'package:quiz_khel/pages/auth/login_page.dart';
import 'package:quiz_khel/pages/auth/signup_page.dart';
import 'package:quiz_khel/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth Demo',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home:SignupPage(),  
      
    );
  }
}
