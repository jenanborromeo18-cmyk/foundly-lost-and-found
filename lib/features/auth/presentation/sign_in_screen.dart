import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_isSignUp) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (mounted && response.session == null) {
          _message('Check your email to confirm your account.');
        }
      } else {
        await auth.signInWithPassword(
            email: _email.text.trim(), password: _password.text);
      }
    } on AuthException catch (error) {
      if (mounted) {
        _message(error.message, error: true);
      }
    } catch (_) {
      if (mounted) {
        _message('Could not connect. Check your connection and try again.',
            error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.danger : AppColors.ink,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                          color: AppColors.paleTeal,
                          borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.volunteer_activism_rounded,
                          color: AppColors.teal, size: 30),
                    ),
                    const SizedBox(height: 28),
                    Text(_isSignUp ? 'Join your community' : 'Welcome back',
                        style: const TextStyle(
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(height: 9),
                    Text(
                        _isSignUp
                            ? 'Create an account to help things find their way home.'
                            : 'Sign in to find what matters or return something you found.',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 15, height: 1.5)),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(children: [
                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                                labelText: 'Your name',
                                prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter your name'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                              labelText: 'Email address',
                              prefixIcon: Icon(Icons.mail_outline)),
                          validator: (value) =>
                              value == null || !value.contains('@')
                                  ? 'Enter a valid email address'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: [
                            _isSignUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password
                          ],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.length < 6
                                  ? 'Use at least 6 characters'
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(
                                    _isSignUp ? 'Create account' : 'Sign in'),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(_isSignUp
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('A little kindness can bring a lot back.',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
