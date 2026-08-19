import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/session_controller.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _consent = false;
  bool _consentError = false;
  bool _obscure = true;
  bool _submitting = false;
  Object? _error;
  String? _verificationEmail;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (!_consent) {
      setState(() => _consentError = true);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .register(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            phone: _phone.text,
          );
      if (!mounted) return;
      if (result.requiresVerification) {
        setState(() => _verificationEmail = _email.text.trim());
      } else {
        context.go('/map');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_verificationEmail != null) {
      return Scaffold(
        body: AuthBackdrop(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 54,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            l10n.verificationTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.verificationBody(_verificationEmail!),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => context.go('/auth/login'),
                            child: Text(l10n.backToLogin),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => context.go('/map'),
                            child: Text(l10n.continueAsGuest),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: AuthBackdrop(
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CivicBrand(compact: true),
                          const SizedBox(height: 24),
                          Text(
                            l10n.registerTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(l10n.registerSubtitle),
                          const SizedBox(height: 22),
                          if (_error != null) ...[
                            ErrorBanner(error: _error!),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            key: const ValueKey('register-name'),
                            controller: _name,
                            enabled: !_submitting,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.length < 2) {
                                return l10n.fullNameMinLength;
                              }
                              if (text.length > 255) {
                                return l10n.fullNameMaxLength;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: l10n.fullNameLabel,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('register-email'),
                            controller: _email,
                            enabled: !_submitting,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            validator: (value) => emailError(l10n, value),
                            decoration: InputDecoration(
                              labelText: l10n.emailLabel,
                              prefixIcon: const Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            enabled: !_submitting,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: l10n.phoneLabel,
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('register-password'),
                            controller: _password,
                            enabled: !_submitting,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                passwordError(l10n, value, enforceLength: true),
                            decoration: InputDecoration(
                              labelText: l10n.passwordLabel,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? l10n.showPassword
                                    : l10n.hidePassword,
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirm,
                            enabled: !_submitting,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            validator: (value) => value != _password.text
                                ? l10n.passwordMismatch
                                : null,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: l10n.confirmPasswordLabel,
                              prefixIcon: const Icon(
                                Icons.verified_user_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            key: const ValueKey('register-consent'),
                            value: _consent,
                            onChanged: _submitting
                                ? null
                                : (value) => setState(() {
                                    _consent = value ?? false;
                                    if (_consent) _consentError = false;
                                  }),
                            title: Text(
                              l10n.privacyConsent,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            subtitle: _consentError
                                ? Text(
                                    l10n.privacyConsentRequired,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  )
                                : null,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const ValueKey('register-submit'),
                            onPressed: _submitting ? null : _submit,
                            child: SubmitLabel(
                              busy: _submitting,
                              label: l10n.registerAction,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: Text(l10n.alreadyAccount)),
                              TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => context.go('/auth/login'),
                                child: Text(l10n.loginAction),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
