import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/validators.dart';
import '../../widgets/crisis_fab.dart';
import '../../widgets/notebook.dart';
import '../../core/mood_color.dart';
import 'auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.onSwitchToSignIn});

  final VoidCallback onSwitchToSignIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _authService = AuthService(Supabase.instance.client);
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;
  bool _submitting = false;
  // Errors stay hidden until the first submit, then update live as the user fixes them.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _googleSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final error = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _displayNameController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleSubmitting = true;
      _error = null;
    });
    final error = await _authService.signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _googleSubmitting = false;
    });
    if (error != null) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('MindBridge'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: const [HelpAction()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Your space.',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Highlight(
                    'Create your account.',
                    color: moodColor(5),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: cs.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Google first
                  OutlinedButton.icon(
                    onPressed: _googleSubmitting ? null : _signInWithGoogle,
                    icon: _googleSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : SvgPicture.asset(
                            'assets/google_logo.svg',
                            width: 18,
                            height: 18,
                          ),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AutofillGroup(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autovalidate,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                            ),
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Display name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.newUsername],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return "That email doesn't look right";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              helperText: kPasswordHint,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                              ),
                            ),
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: validatePassword,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                tooltip: _obscureConfirm
                                    ? 'Show password'
                                    : 'Hide password',
                              ),
                            ),
                            obscureText: _obscureConfirm,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (v) => validatePasswordConfirmation(
                              v,
                              _passwordController.text,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: Text(
                              _submitting
                                  ? 'Creating account…'
                                  : 'Create account',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onSwitchToSignIn,
                    child: const Text('Already have an account? Log in'),
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
