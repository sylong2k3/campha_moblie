import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/session_controller.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.returnTo,
    @visibleForTesting this.debugTestAccountPassword,
  });

  final String? returnTo;
  final String? debugTestAccountPassword;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailKey = GlobalKey();
  final _passwordKey = GlobalKey();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _submitting = false;
  Object? _error;

  String get _configuredTestAccountPassword =>
      widget.debugTestAccountPassword ?? _testAccountPassword;

  Future<void> _loginTestAccount(_TestAccount account) async {
    final password = _configuredTestAccountPassword;
    _formKey.currentState?.reset();
    _emailController.text = account.email;
    _passwordController.text = password;
    setState(() {
      _error = null;
      _obscurePassword = true;
    });
    if (password.isEmpty) {
      _passwordFocus.requestFocus();
      return;
    }
    await _submit();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) {
      final emailInvalid =
          emailError(context.l10n, _emailController.text) != null;
      final targetContext = emailInvalid
          ? _emailKey.currentContext
          : _passwordKey.currentContext;
      (emailInvalid ? _emailFocus : _passwordFocus).requestFocus();
      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          alignment: 0.25,
        );
      }
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      context.go(widget.returnTo ?? '/map');
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
      body: AuthBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Center(child: CivicBrand()),
                                const SizedBox(height: 30),
                                Text(
                                  l10n.loginTitle,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.loginSubtitle,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                if (_error != null) ...[
                                  ErrorBanner(error: _error!),
                                  const SizedBox(height: 16),
                                ],
                                KeyedSubtree(
                                  key: _emailKey,
                                  child: TextFormField(
                                    key: const ValueKey('login-email'),
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    enabled: !_submitting,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                      AutofillHints.email,
                                    ],
                                    autocorrect: false,
                                    validator: (value) =>
                                        emailError(l10n, value),
                                    decoration: InputDecoration(
                                      labelText: l10n.emailLabel,
                                      prefixIcon: const Icon(
                                        Icons.alternate_email,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                KeyedSubtree(
                                  key: _passwordKey,
                                  child: TextFormField(
                                    key: const ValueKey('login-password'),
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    enabled: !_submitting,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    validator: (value) =>
                                        passwordError(l10n, value),
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: l10n.passwordLabel,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? l10n.showPassword
                                            : l10n.hidePassword,
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    key: const ValueKey('forgot-password-link'),
                                    onPressed: _submitting
                                        ? null
                                        : () => context.push(
                                            '/auth/forgot-password',
                                          ),
                                    child: Text(l10n.forgotPasswordAction),
                                  ),
                                ),
                                if (kDebugMode || _testLoginEnabled) ...[
                                  _TestAccountsStrip(
                                    enabled: !_submitting,
                                    passwordConfigured:
                                        _configuredTestAccountPassword
                                            .isNotEmpty,
                                    onSelected: _loginTestAccount,
                                  ),
                                  const SizedBox(height: 14),
                                ] else
                                  const SizedBox(height: 6),
                                FilledButton(
                                  key: const ValueKey('login-submit'),
                                  onPressed: _submitting ? null : _submit,
                                  child: SubmitLabel(
                                    busy: _submitting,
                                    label: l10n.loginAction,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton(
                                  key: const ValueKey('guest-continue'),
                                  onPressed: _submitting
                                      ? null
                                      : () => context.go(
                                          guestReturnTo(widget.returnTo),
                                        ),
                                  child: Text(l10n.continueAsGuest),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(child: Text(l10n.noAccount)),
                                    TextButton(
                                      onPressed: _submitting
                                          ? null
                                          : () =>
                                                context.push('/auth/register'),
                                      child: Text(l10n.registerAction),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _testAccountPassword = String.fromEnvironment('TEST_ACCOUNT_PASSWORD');
const _testLoginEnabled = bool.fromEnvironment('ENABLE_TEST_LOGIN');

class _TestAccount {
  const _TestAccount({
    required this.roleCode,
    required this.email,
    required this.icon,
  });

  final String roleCode;
  final String email;
  final IconData icon;
}

const _testAccounts = <_TestAccount>[
  _TestAccount(
    roleCode: 'citizen',
    email: 'citizen@campha.gov.vn',
    icon: Icons.person_outline,
  ),
  _TestAccount(
    roleCode: 'ubnd_tp',
    email: 'ubnd@campha.gov.vn',
    icon: Icons.account_balance_outlined,
  ),
  _TestAccount(
    roleCode: 'so_xd',
    email: 'xaydung@campha.gov.vn',
    icon: Icons.apartment_outlined,
  ),
  _TestAccount(
    roleCode: 'so_tnmt',
    email: 'tnmt@campha.gov.vn',
    icon: Icons.map_outlined,
  ),
  _TestAccount(
    roleCode: 'system_admin',
    email: 'admin@campha.gov.vn',
    icon: Icons.admin_panel_settings_outlined,
  ),
];

class _TestAccountsStrip extends StatelessWidget {
  const _TestAccountsStrip({
    required this.enabled,
    required this.passwordConfigured,
    required this.onSelected,
  });

  final bool enabled;
  final bool passwordConfigured;
  final ValueChanged<_TestAccount> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      key: const ValueKey('test-accounts-panel'),
      container: true,
      label: 'Đăng nhập nhanh bằng tài khoản kiểm thử theo vai trò',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 17, color: colors.tertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Đăng nhập nhanh',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.tertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${kDebugMode ? 'DEBUG' : 'TEST'}  •  Kéo ngang',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            key: const ValueKey('test-accounts-scroll'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final account in _testAccounts)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: account.email,
                      child: OutlinedButton.icon(
                        key: ValueKey('test-account-${account.roleCode}'),
                        onPressed: enabled ? () => onSelected(account) : null,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: colors.tertiaryContainer.withValues(
                            alpha: 0.42,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        icon: Icon(account.icon, size: 18),
                        label: Text(
                          _testRoleLabel(context.l10n, account.roleCode),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!passwordConfigured) ...[
            const SizedBox(height: 6),
            Text(
              'Thiếu TEST_ACCOUNT_PASSWORD; nút chỉ điền email.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}

String _testRoleLabel(AppLocalizations l10n, String roleCode) =>
    switch (roleCode) {
      'citizen' => l10n.roleCitizen,
      'ubnd_tp' => l10n.roleUbndTp,
      'so_xd' => l10n.roleSoXd,
      'so_tnmt' => l10n.roleSoTnmt,
      'system_admin' => l10n.roleSystemAdmin,
      _ => roleCode,
    };
