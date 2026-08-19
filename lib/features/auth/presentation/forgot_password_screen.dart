import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../domain/session_controller.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;
  Object? _error;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final message = await ref
          .read(sessionControllerProvider.notifier)
          .forgotPassword(_email.text);
      if (mounted) setState(() => _message = message);
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
      appBar: AppBar(),
      body: AuthBackdrop(
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: _message != null
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.outgoing_mail,
                                size: 52,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.forgotSuccessTitle,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(_message!, textAlign: TextAlign.center),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: () => context.go('/auth/login'),
                                child: Text(l10n.backToLogin),
                              ),
                            ],
                          )
                        : Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const CivicBrand(compact: true),
                                const SizedBox(height: 26),
                                Text(
                                  l10n.forgotTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.forgotSubtitle),
                                const SizedBox(height: 22),
                                if (_error != null) ...[
                                  ErrorBanner(error: _error!),
                                  const SizedBox(height: 14),
                                ],
                                TextFormField(
                                  key: const ValueKey('forgot-email'),
                                  controller: _email,
                                  enabled: !_submitting,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autocorrect: false,
                                  validator: (value) => emailError(l10n, value),
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: l10n.emailLabel,
                                    prefixIcon: const Icon(
                                      Icons.alternate_email,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FilledButton(
                                  key: const ValueKey('forgot-submit'),
                                  onPressed: _submitting ? null : _submit,
                                  child: SubmitLabel(
                                    busy: _submitting,
                                    label: l10n.sendInstructionAction,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => context.go('/auth/login'),
                                  child: Text(l10n.backToLogin),
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
