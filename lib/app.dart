import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class OnePlusOneApp extends StatelessWidget {
  const OnePlusOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1+1',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
