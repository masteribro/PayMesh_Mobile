import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/send_money_screen.dart';
import 'presentation/screens/transaction_history_screen.dart';

void main() {
  runApp(const PayMeshApp());
}

class PayMeshApp extends StatelessWidget {
  const PayMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PayMesh',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: Brightness.light,
            ),
            fontFamily: 'Poppins',
            textTheme: TextTheme(
              headlineLarge: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
              headlineMedium: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
              titleLarge: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
              bodyLarge: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4B5563),
              ),
              bodyMedium: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF6B7280),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 4,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB), width: 2),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 2,
                ),
              ),
              hintStyle: TextStyle(
                color: const Color(0xFF9CA3AF),
                fontSize: 13.sp,
              ),
              labelStyle: TextStyle(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
            ),
          ),
          home: const SplashScreen(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const MainNavigationScreen(),
          },
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SendMoneyScreen(),
    TransactionHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 11.sp),
        unselectedLabelStyle: TextStyle(fontSize: 11.sp),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Send'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
