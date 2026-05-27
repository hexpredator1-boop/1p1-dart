import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'logic/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const OnePlusOneApp());
}
