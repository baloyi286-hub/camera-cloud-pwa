import 'package:flutter/material.dart';
import 'camera_screen.dart';

void main() => runApp(const CameraCloudApp());

class CameraCloudApp extends StatelessWidget {
  const CameraCloudApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Camera Cloud',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF25A67B), useMaterial3: true, brightness: Brightness.dark),
    home: const CameraScreen(),
  );
}
