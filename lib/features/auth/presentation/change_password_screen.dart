import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/session_controller.dart';
import 'auth_widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  Object? _error;

  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .changePassword(oldPassword: _old.text, newPassword: _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.changePasswordSuccess)),
      );
      context.go('/auth/login');
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.changePasswordTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.changePasswordSubtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        if (_error != null) ...[
                          ErrorBanner(error: _error!),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          key: const ValueKey('old-password'),
                          controller: _old,
                          obscureText: _obscure,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          validator: (value) => passwordError(l10n, value),
                          decoration: InputDecoration(
                            labelText: l10n.oldPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_clock_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('new-password'),
                          controller: _next,
                          obscureText: _obscure,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final error = passwordError(
                              l10n,
                              value,
                              enforceLength: true,
                            );
                            if (error != null) {
                              return error;
                            }
                            if (value == _old.text) {
                              return l10n.passwordMustDiffer;
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: l10n.newPasswordLabel,
                            prefixIcon: const Icon(Icons.password_outlined),
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
                          obscureText: _obscure,
                          enabled: !_submitting,
                          textInputAction: TextInputAction.done,
                          validator: (value) => value != _next.text
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
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const ValueKey('change-password-submit'),
                          onPressed: _submitting ? null : _submit,
                          child: SubmitLabel(
                            busy: _submitting,
                            label: l10n.changePasswordAction,
                          ),
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
}
