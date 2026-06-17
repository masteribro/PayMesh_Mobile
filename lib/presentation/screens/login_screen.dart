import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../blocs/auth/auth_bloc.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showResponseDialog(BuildContext context,
      {required bool success,
      required String title,
      required Map<String, dynamic> body}) {
    final color =
        success ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final icon =
        success ? Icons.check_circle_outline : Icons.error_outline;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: color),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(body),
                    style: TextStyle(
                        fontFamily: 'monospace', fontSize: 11.sp),
                  ),
                ),
              ),
              if (success) ...[
                SizedBox(height: 2.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: color),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context)
                          .pushReplacementNamed('/home');
                    },
                    child: const Text('Continue to Home',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _showResponseDialog(context,
                success: true,
                title: state.title,
                body: state.response.toJson());
          } else if (state is AuthFailure) {
            _showResponseDialog(context,
                success: false, title: state.title, body: state.body);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10.h),
                      Text(
                        'PayMesh',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              color: const Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Offline-First Digital Payments',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: const Color(0xFF6B7280)),
                      ),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          hintText: 'Enter your password',
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Email and password are required'),
                                  ));
                                  return;
                                }
                                context.read<AuthBloc>().add(
                                      LoginSubmitted(
                                        email: _emailController.text
                                            .trim(),
                                        password:
                                            _passwordController.text,
                                      ),
                                    );
                              },
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Login'),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    ),
                            child: Text(
                              'Sign Up',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
