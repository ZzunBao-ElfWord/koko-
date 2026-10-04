import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength: at least 8 chars, containing uppercase,
  /// lowercase, and digit.
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return AppLocalizations.of(context)!.passwordMinLength;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return AppLocalizations.of(context)!.passwordUppercase;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return AppLocalizations.of(context)!.passwordLowercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return AppLocalizations.of(context)!.passwordDigit;
    }
    return null;
  }

  String? _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      return AppLocalizations.of(context)!.enterEmail;
    }
    if (!_isValidEmail(email)) {
      return AppLocalizations.of(context)!.validEmail;
    }
    if (password.isEmpty) {
      return AppLocalizations.of(context)!.enterPassword;
    }
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      return passwordError;
    }
    return null;
  }

  Future<void> _login() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      developer.log('Login attempt: email=${_emailController.text.trim()}', name: 'LoginScreen');
      await authRepo.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        context.go('/home');
      }
    } on DioException catch (e) {
      developer.log('Login DioException: type=${e.type} message=${e.message} response=${e.response?.data}', name: 'LoginScreen');
      String msg;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          msg = '连接超时，请检查网络';
          break;
        case DioExceptionType.badCertificate:
          msg = 'SSL 证书验证失败';
          break;
        case DioExceptionType.connectionError:
          msg = '无法连接到服务器 (${e.message})';
          break;
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          final data = e.response?.data;
          if (status == 401) {
            msg = '邮箱或密码错误';
          } else if (status == 404) {
            msg = 'API 端点不存在 (404)，可能是 URL 配置错误';
          } else if (status == 502 || status == 503 || status == 504) {
            msg = '服务器暂时不可用 ($status)';
          } else {
            msg = '服务器返回错误: $status | ${data?.toString() ?? e.message}';
          }
          break;
        default:
          msg = '网络错误: ${e.message}';
      }
      setState(() => _error = '${AppLocalizations.of(context)!.loginFailed}: $msg');
    } catch (e) {
      developer.log('Login unexpected error: $e', name: 'LoginScreen');
      setState(() => _error = '${AppLocalizations.of(context)!.loginFailed}: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.welcomeToStoat,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.signInToAccount,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.errorColor)),
                  ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(AppLocalizations.of(context)!.signIn),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text('${AppLocalizations.of(context)!.noAccount} ${AppLocalizations.of(context)!.register}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
