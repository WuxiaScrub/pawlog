import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';

const _webClientId =
    '91727702481-8n5ajp9aqs9kekphcikmaatkr57avftr.apps.googleusercontent.com';
const _iosClientId =
    '91727702481-d5e8sjm6uhfoaaegm3qp6aksc9bcturn.apps.googleusercontent.com';
const _androidClientId =
    '91727702481-406bebdjscqh5dna6og0sce1rjv21ns7.apps.googleusercontent.com';

const _skipKey = 'auth_skipped';
const _storage = FlutterSecureStorage();

Future<bool> hasSkippedAuth() async {
  final value = await _storage.read(key: _skipKey);
  return value == 'true';
}

Future<void> setAuthSkipped() async {
  await _storage.write(key: _skipKey, value: 'true');
}

Future<void> clearAuthSkipped() async {
  await _storage.delete(key: _skipKey);
}

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  bool _showEmailForm = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        await supabase.auth.signUp(email: email, password: password);
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
      await clearAuthSkipped();
      if (mounted) widget.onContinue();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        clientId: !kIsWeb && Platform.isIOS
            ? _iosClientId
            : !kIsWeb && Platform.isAndroid
                ? _androidClientId
                : null,
        serverClientId: _webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        setState(() => _error = 'Could not get Google credentials.');
        return;
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      await clearAuthSkipped();
      if (mounted) widget.onContinue();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _skipAuth() async {
    await setAuthSkipped();
    if (mounted) widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.pets,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'PawLog',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your cat care companion',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            OutlinedButton.icon(
              onPressed: _loading ? null : _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 24),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            if (!_showEmailForm)
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => setState(() => _showEmailForm = true),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Continue with email'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (_showEmailForm) ...[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isSignUp ? 'Create Account' : 'Sign In'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _isSignUp = !_isSignUp;
                          _error = null;
                        }),
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign in'
                      : "Don't have an account? Sign up",
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loading ? null : _skipAuth,
              child: Text(
                'Continue without an account',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'PawLog is not a substitute for veterinary care.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
