import 'package:flutter/material.dart';
import 'package:cangaia_de_jegue/views/login_view.dart';

void main() {
  runApp(const CangaiaApp());
}

class CangaiaApp extends StatelessWidget {
  const CangaiaApp({super.key});

  static const Color _roxoCangaia = Color(0xFF7B2CF5);
  static const Color _pretoCamisa = Color(0xFF121212);
  static const Color _cinzaEscuro = Color(0xFF1E1E1E);
  static const Color _cinzaBorda = Color(0xFF343434);
  static const Color _brancoQuebrado = Color(0xFFF5F5F5);
  static const Color _vermelhoLogo = Color(0xFFDD3B3B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cangaia de Jegue - Vendas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _roxoCangaia,
          primary: _roxoCangaia,
          secondary: _vermelhoLogo,
          surface: _cinzaEscuro,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: _pretoCamisa,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: _cinzaEscuro,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _roxoCangaia, width: 0.8),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF262626),
          labelStyle: const TextStyle(color: _brancoQuebrado),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _cinzaBorda),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _roxoCangaia, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: _brancoQuebrado),
          bodyMedium: TextStyle(color: _brancoQuebrado),
          titleLarge: TextStyle(color: _brancoQuebrado),
          titleMedium: TextStyle(color: _brancoQuebrado),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _roxoCangaia,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _brancoQuebrado,
            side: const BorderSide(color: _roxoCangaia),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}
