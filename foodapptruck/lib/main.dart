import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:foodapptruck/login.dart';
import 'firebase_options.dart'; // Ensure you have this for Firebase options

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensures binding is initialized before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize Firebase
  ).catchError((error) {
    // Handle errors in Firebase initialization
    print("Firebase initialization error: $error");
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Basics',
      theme: ThemeData(
        // Define the default brightness and colors.
        brightness: Brightness.light,
        primaryColor: Colors.deepOrange,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.cyan[600], // Used to be `accentColor`
        ),

        // Define the default font family.
        fontFamily: 'Georgia',

        // Define the default TextTheme. Use this to specify the default
        // text styling for headlines, titles, bodies of text, and more.
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
          bodyMedium: TextStyle(
              fontSize: 14.0, fontFamily: 'Hind'), // Corrected line here
        ),
      ),
      home: const LoginPage(),
    );
  }
}
