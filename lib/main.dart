import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'core/colors.dart';
import 'core/constants.dart';
import 'core/supabase_config.dart';
import 'presentation/pages/splash/modern_splash_screen.dart';
import 'presentation/pages/main_navigation.dart';
import 'presentation/pages/login/login_screen.dart';
import 'presentation/pages/signup/signup_screen.dart';
import 'presentation/pages/search/search_screen.dart';
import 'presentation/pages/bookings/bookings_screen.dart';
import 'presentation/pages/profile/profile_screen.dart';
import 'presentation/pages/booking/booking_selection_screen.dart';
import 'presentation/pages/booking/booking_confirmation_screen.dart';
import 'presentation/pages/booking/booking_success_screen.dart';
import 'presentation/providers/parking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Maps for Android
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }

  try {
    // Initialize Supabase with deep link handling
    await SupabaseConfig.initialize();

    // Handle OAuth redirects (deep links)
    // This ensures the app receives the callback after Google Sign-In
    debugPrint('✅ App initialized with deep link support');

    runApp(const ProviderScope(child: ParkingApp()));
  } catch (e) {
    // Show error screen if Supabase fails to initialize
    runApp(ProviderScope(child: ParkingApp(error: e.toString())));
  }
}

class ParkingApp extends StatelessWidget {
  final String? error;

  const ParkingApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    // Show error screen if initialization failed
    if (error != null) {
      return MaterialApp(
        title: 'Parking App - Error',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Configuration Error',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize. Check your .env file.\n\nError: $error',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Normal app
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(context),
      home: const ModernSplashScreen(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/search': (context) => const SearchScreen(),
        '/bookings': (context) => const BookingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/booking-selection') {
          final parkingSpace = settings.arguments as ParkingSpaceCard;
          return MaterialPageRoute(
            builder: (context) => BookingSelectionScreen(parkingSpace: parkingSpace),
          );
        }
        if (settings.name == '/booking-confirmation') {
          final bookingData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(bookingData: bookingData),
          );
        }
        if (settings.name == '/booking-success') {
          final bookingData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(bookingData: bookingData),
          );
        }
        return null;
      },
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    // Airbnb-style: Always light mode, no dark mode
    final colorScheme = AppColors.generateColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.primaryBackground,

      // Airbnb-Inspired Typography - Clean & readable
      textTheme: const TextTheme(
        // Display - Large headers
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),

        // Headlines - Section titles
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Titles - Card/List titles
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),

        // Body - Main text
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),

        // Labels & Captions
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),
      ),

      // AppBar - Clean white with no elevation
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shadowColor: AppColors.shadowLight,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Cards - White with subtle shadow
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shadowColor: AppColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius16),
        ),
      ),

      // Inputs - Light gray background
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          borderSide: const BorderSide(color: AppColors.statusError, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Elevated Button - Black background
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ctaPrimary,
          foregroundColor: AppColors.ctaOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius12),
          ),
          minimumSize: const Size(0, 56),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button - Black border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius12),
          ),
          minimumSize: const Size(0, 56),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // SnackBar
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Divider - Very light gray
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
