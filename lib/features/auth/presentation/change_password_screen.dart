import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
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
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                  boxShadow: AppColors.cardShadow(
                    Theme.of(context).brightness,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.changePasswordTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.changePasswordSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          ErrorBanner(error: _error!),
                          const SizedBox(height: 16),
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
                        const SizedBox(height: 14),
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
                        // Password strength indicator
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _next,
                          builder: (context, value, _) {
                            final strength = _passwordStrength(value.text);
                            if (value.text.isEmpty) {
                              return const SizedBox(height: 14);
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: strength.value,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        color: strength.color,
                                        minHeight: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    strength.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: strength.color,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
                        const SizedBox(height: 24),
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

  static ({double value, Color color, String label}) _passwordStrength(
    String password,
  ) {
    if (password.length < 6) {
      return (value: 0.2, color: const Color(0xFFB42318), label: 'Yếu');
    }
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return switch (score) {
      <= 1 => (value: 0.35, color: const Color(0xFFD97706), label: 'Trung bình'),
      <= 3 => (value: 0.65, color: const Color(0xFF1677A3), label: 'Khá'),
      _ => (value: 1.0, color: const Color(0xFF087A5B), label: 'Mạnh'),
    };
  }
}
