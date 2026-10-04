import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }

  /// Validate username: 3-32 alphanumeric/underscore chars
  String? _validateUsername(String username) {
    if (username.isEmpty) {
      return null; // username is optional
    }
    if (username.length < 3 || username.length > 32) {
      return AppLocalizations.of(context)!.usernameLength;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return AppLocalizations.of(context)!.usernameFormat;
    }
    return null;
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
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty) {
      return AppLocalizations.of(context)!.enterEmail;
    }
    if (!_isValidEmail(email)) {
      return AppLocalizations.of(context)!.validEmail;
    }
    final usernameError = _validateUsername(username);
    if (usernameError != null) {
      return usernameError;
    }
    if (password.isEmpty) {
      return AppLocalizations.of(context)!.enterPassword;
    }
    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      return passwordError;
    }
    if (confirmPassword.isEmpty) {
      return AppLocalizations.of(context)!.enterConfirmPassword;
    }
    if (password != confirmPassword) {
      return AppLocalizations.of(context)!.passwordsNotMatch;
    }
    return null;
  }

  Future<void> _register() async {
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
      await authRepo.register(
        _emailController.text.trim(),
        _passwordController.text,
        username: _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : null,
      );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = '${AppLocalizations.of(context)!.registrationFailed}: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.createAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
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
                decoration: const InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: AppLocalizations.of(context)!.usernameOptional,
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmPassword,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(AppLocalizations.of(context)!.register),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('${AppLocalizations.of(context)!.hasAccount} ${AppLocalizations.of(context)!.login}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
