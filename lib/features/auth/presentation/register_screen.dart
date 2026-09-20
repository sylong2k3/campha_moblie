import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/session_controller.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final TapGestureRecognizer _privacyTapRecognizer;

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
  void initState() {
    super.initState();
    _privacyTapRecognizer = TapGestureRecognizer()..onTap = _openPrivacyPolicy;
  }

  @override
  void dispose() {
    _privacyTapRecognizer.dispose();
    for (final controller in [_name, _email, _phone, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.tryParse(ApiConfig.privacyPolicyUrl);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.cannotOpenUrl(ApiConfig.privacyPolicyUrl),
            ),
          ),
        );
      }
    }
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
                      boxShadow: AppColors.cardElevatedShadow(
                        Theme.of(context).brightness,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              size: 36,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.verificationTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.verificationBody(_verificationEmail!),
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
                          const SizedBox(height: 28),
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
                    boxShadow: AppColors.cardElevatedShadow(
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
                          const CivicBrand(compact: true),
                          const SizedBox(height: 24),
                          Text(
                            l10n.registerTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.registerSubtitle,
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
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 14),
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
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Checkbox(
                                  key: const ValueKey('register-consent'),
                                  value: _consent,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: _submitting
                                      ? null
                                      : (value) => setState(() {
                                          _consent = value ?? false;
                                          if (_consent) _consentError = false;
                                        }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _submitting
                                      ? null
                                      : () => setState(() {
                                          _consent = !_consent;
                                          if (_consent) _consentError = false;
                                        }),
                                  child: Text.rich(
                                    TextSpan(
                                      text: l10n.privacyConsentPrefix,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            height: 1.35,
                                          ),
                                      children: [
                                        TextSpan(
                                          text: l10n.privacyPolicyLinkText,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: _privacyTapRecognizer,
                                        ),
                                        TextSpan(
                                          text: l10n.privacyConsentSuffix,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_consentError) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 36),
                              child: Text(
                                l10n.privacyConsentRequired,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const ValueKey('register-submit'),
                            onPressed: _submitting ? null : _submit,
                            child: SubmitLabel(
                              busy: _submitting,
                              label: l10n.registerAction,
                            ),
                          ),
                          const SizedBox(height: 14),
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
