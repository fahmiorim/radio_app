import 'package:flutter/material.dart';
import 'app/app.dart';

Future<void> main() async {
  // Initialize the application
  await initializeApp();
  
  // Run the application
  runApp(const RadioApp());
}
