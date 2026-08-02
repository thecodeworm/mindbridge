import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/recovery_state.dart';
import '../../core/validators.dart';
import 'auth_service.dart';

/// Shown in place of [HomeScreen]/[SignInScreen] by `AuthGate` when the
/// auth stream reports `AuthChangeEvent.passwordRecovery` — i.e. the user
/// opened the app via the `com.mindbridge.mindbridge://reset-callback`
/// deep link from a password-reset email.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _authService = AuthService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _submitting = false;
  bool _cancelling = false;
  bool _obscurePassword = true;
  bool _done = false;
  bool _expired = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await _authService.updatePassword(_passwordController.text);
    if (!mounted) return;

    if (error != null) {
      // A session/JWT error means the recovery link expired before submission.
      final lc = error.toLowerCase();
      final isSessionError = lc.contains('session') ||
          lc.contains('jwt') ||
          lc.contains('expired') ||
          lc.contains('missing');
      setState(() {
        _submitting = false;
        if (isSessionError) {
          _expired = true;
        } else {
          _error = error;
        }
      });
      return;
    }

    // Show the success screen. RecoveryState stays true so AuthGate keeps
    // rendering this widget. _cancel() (called by "Back to sign in") clears it.
    setState(() {
      _submitting = false;
      _done = true;
    });
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    await _authService.signOut();
    await RecoveryState.set(false);
  }

  bool get _isGoogleOnly {
    final identities = Supabase.instance.client.auth.currentUser?.identities ?? [];
    return identities.isNotEmpty && identities.every((i) => i.provider != 'email');
  }

  Widget _brandHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'MindBridge',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track your mood, grow your mind.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _centeredCard(BuildContext context, {required Widget child}) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _brandHeader(context),
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_done) {
      return _centeredCard(context, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('✅', textAlign: TextAlign.center, style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Password updated',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You can sign in with your new password now.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cancel,
            child: const Text('Back to sign in'),
          ),
        ],
      ));
    }

    if (_expired) {
      return _centeredCard(context, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This link has expired',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Reset links only work once and expire after a while. Request a new one from the sign in page.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _cancel,
            child: const Text('Request a new link'),
          ),
        ],
      ));
    }

    if (_isGoogleOnly) {
      return _centeredCard(context, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You signed up with Google',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "There's no password to reset — just use the Google button to sign in.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _cancel,
            child: const Text('Back to sign in'),
          ),
        ],
      ));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  _brandHeader(context),
                  const SizedBox(height: 32),
                  Text(
                    'Set a new password',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'New password',
                            helperText: kPasswordHint,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                            ),
                          ),
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: validatePassword,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmController,
                          decoration: const InputDecoration(labelText: 'Confirm new password'),
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (v) =>
                              validatePasswordConfirmation(v, _passwordController.text),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: (_submitting || _cancelling) ? null : _submit,
                          child: Text(_submitting ? 'Saving…' : 'Save new password'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: (_submitting || _cancelling) ? null : _cancel,
                          child: Text(_cancelling ? 'Cancelling…' : 'Cancel'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
