//import 'package:kskfinance/Views/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kskfinance/Screens/Main/IntroductionDcreen.dart';
import 'package:kskfinance/Screens/Main/home_screen.dart';

import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: const Color.fromARGB(255, 243, 242, 241),
  primarySwatch: Colors.blue,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blueAccent,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: GoogleFonts.tinos(
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
  textTheme: GoogleFonts.tinosTextTheme(
    ThemeData.light().textTheme,
  ).copyWith(
    bodyLarge: const TextStyle(color: Colors.black, fontSize: 18),
    bodyMedium: const TextStyle(color: Colors.black, fontSize: 16),
    headlineSmall: const TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    labelLarge: TextStyle(
      color: const Color.fromARGB(255, 255, 215, 0),
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: GoogleFonts.tinos().fontFamily,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: Colors.blue,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.blue),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
    labelStyle: TextStyle(
      color: Colors.blue,
      fontFamily: GoogleFonts.tinos().fontFamily,
    ),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    elevation: 10.0,
  ),
  fontFamily: GoogleFonts.tinos().fontFamily,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  runApp(
    ProviderScope(
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;

  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      home: isFirstLaunch ? const IntroductionScreen() : const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
