import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_clock_clone/providers/login_notifier_provider.dart';
import 'package:web_clock_clone/widgets/flipclock/flip_clock.dart';
import 'package:web_clock_clone/widgets/input_form_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late FocusNode _companyCodeNode;
  late FocusNode _usernameNode;
  late FocusNode _passwordNode;
  String _companyCode = '';
  String _username = '';
  String _password = '';

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    _formKey.currentState!.save();

    ref
        .read(loginNotifierProvider.notifier)
        .submit(
          _companyCode.trim(),
          _username.trim(),
          _password,
          onMaxRetriesExceeded: () {
            // Reset the form and clear the local fields so the UI reflects the reset.
            _formKey.currentState?.reset();
            setState(() {
              _companyCode = '';
              _username = '';
              _password = '';
            });
          },
        );
  }

  @override
  void initState() {
    super.initState();
    _companyCodeNode = FocusNode();
    _usernameNode = FocusNode();
    _passwordNode = FocusNode();
  }

  @override
  void dispose() {
    _companyCodeNode.dispose();
    _usernameNode.dispose();
    _passwordNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;

    final loginAsync = ref.watch(loginNotifierProvider);
    final notifier = ref.read(loginNotifierProvider.notifier);

    final isLoading = loginAsync is AsyncLoading;
    final loginState = loginAsync.value;
    final isFailure = loginState?.status == LoginStatus.failure;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: deviceHeight * 0.75),
            child: Column(
              spacing: 28,
              mainAxisAlignment: .center,
              children: [
                const FlipClock(
                  hourFormat: .h12,
                  digitSize: 45,
                  width: 35,
                  height: 56,
                ),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191B21),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      spacing: 12,
                      crossAxisAlignment: .stretch,
                      children: [
                        InputFormField(
                          focusNode: _companyCodeNode,
                          labelText: 'Company Code',
                          isRequired: true,
                          prefixIcon: const Icon(Icons.apartment),
                          hint: 'Enter your company code',
                          keyboardType: TextInputType.name,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your company code';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              setState(() => _companyCode = value ?? ''),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _usernameNode.requestFocus(),
                        ),
                        InputFormField(
                          focusNode: _usernameNode,
                          labelText: 'Username',
                          isRequired: true,
                          prefixIcon: const Icon(Icons.person),
                          hint: 'Enter your username',
                          keyboardType: TextInputType.name,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              setState(() => _username = value ?? ''),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _passwordNode.requestFocus(),
                        ),
                        InputFormField(
                          focusNode: _passwordNode,
                          labelText: 'Password',
                          isRequired: true,
                          prefixIcon: const Icon(Icons.lock),
                          hint: 'Enter your password',
                          isPasswordField: true,
                          onChanged: (value) =>
                              setState(() => _password = value),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              setState(() => _password = value ?? ''),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
                        ),
                        const SizedBox(height: 24),

                        // ── Error message + attempts remaining ───────────────────────
                        if (isFailure) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loginState?.errorMessage ??
                                      'Invalid credentials.',
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${notifier.attemptsRemaining} attempt(s) remaining.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Submit button ────────────────────────────────────────────
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: Icon(Icons.security),
                          label: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Authorize',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                          style: FilledButton.styleFrom(
                            iconColor: Colors.white,
                            backgroundColor: const Color(0xFFC00000),
                            disabledBackgroundColor: const Color(0xFF2A2D34),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
