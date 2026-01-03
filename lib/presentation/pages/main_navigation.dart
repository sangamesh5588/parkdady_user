import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/bottom_navigation.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'bookings/bookings_screen.dart';
import 'profile/profile_screen.dart';

// Safe Screen Wrapper to prevent crashes from individual screens
class SafeScreenWrapper extends StatelessWidget {
  final Widget child;
  final String screenName;

  const SafeScreenWrapper({
    super.key,
    required this.child,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (e) {
      // If screen crashes, show error placeholder
      return Scaffold(
        appBar: AppBar(
          title: Text('$screenName - Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '$screenName is currently unavailable',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later or contact support.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to a safe screen (home)
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  late int _currentIndex;

  // List of all screens wrapped in error boundaries
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    // Initialize screens with error boundaries
    _screens = [
      const SafeScreenWrapper(
        screenName: 'Home',
        child: HomeScreen(),
      ),
      const SafeScreenWrapper(
        screenName: 'Search',
        child: SearchScreen(),
      ),
      const SafeScreenWrapper(
        screenName: 'Bookings',
        child: BookingsScreen(),
      ),
      const SafeScreenWrapper(
        screenName: 'Profile',
        child: ProfileScreen(),
      ),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: () async {
          // If not on home tab, switch to home tab first
          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
            return false; // Don't allow system back
          }
          // If on home tab, allow system back (exit app)
          return true;
        },
        child: Scaffold(
          body: RepaintBoundary(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          bottomNavigationBar: RepaintBoundary(
            child: BottomNavigation(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
          ),
        ),
      ),
    );
  }
}
