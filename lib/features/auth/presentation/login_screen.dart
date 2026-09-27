import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
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

  String get _backDestination => guestReturnTo(widget.returnTo);

  void _goBack() {
    if (_submitting) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(_backDestination);
    }
  }

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
          duration: AppMotion.of(context, AppMotion.state),
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
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(_backDestination);
      },
      child: Scaffold(
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
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          key: const ValueKey('login-back'),
                          onPressed: _submitting ? null : _goBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: Text(l10n.reportBack),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          boxShadow: AppColors.cardElevatedShadow(
                            Theme.of(context).brightness,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Center(child: CivicBrand()),
                                  const SizedBox(height: 32),
                                  Text(
                                    l10n.loginTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.loginSubtitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 28),
                                  if (_error != null) ...[
                                    ErrorBanner(error: _error!),
                                    const SizedBox(height: 18),
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
                                  const SizedBox(height: 16),
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
                                      key: const ValueKey(
                                        'forgot-password-link',
                                      ),
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
                                    const SizedBox(height: 16),
                                  ] else
                                    const SizedBox(height: 8),
                                  _GradientLoginButton(
                                    onPressed: _submitting ? null : _submit,
                                    submitting: _submitting,
                                    label: l10n.loginAction,
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton(
                                    key: const ValueKey('guest-continue'),
                                    onPressed: _submitting
                                        ? null
                                        : () => context.go(_backDestination),
                                    child: Text(l10n.continueAsGuest),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(child: Text(l10n.noAccount)),
                                      TextButton(
                                        onPressed: _submitting
                                            ? null
                                            : () => context.push(
                                                '/auth/register',
                                              ),
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
      ),
    );
  }
}

/// Nút đăng nhập nổi bật với màu primary.
class _GradientLoginButton extends StatelessWidget {
  const _GradientLoginButton({
    required this.onPressed,
    required this.submitting,
    required this.label,
  });

  final VoidCallback? onPressed;
  final bool submitting;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: onPressed != null
            ? colors.primary
            : colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('login-submit'),
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

const _defaultDemoPassword = 'CamPha@2026';
const _testAccountPassword = String.fromEnvironment(
  'TEST_ACCOUNT_PASSWORD',
  defaultValue: _defaultDemoPassword,
);
const _testLoginEnabled = bool.fromEnvironment(
  'ENABLE_TEST_LOGIN',
  defaultValue: true,
);

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
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.badge_outlined,
                  size: 14,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tài khoản mẫu trải nghiệm',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            key: const ValueKey('test-accounts-scroll'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final account in _testAccounts)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TestAccountChip(
                      account: account,
                      enabled: enabled,
                      onTap: () => onSelected(account),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                passwordConfigured
                    ? Icons.lock_open_outlined
                    : Icons.info_outline,
                size: 13,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  passwordConfigured
                      ? 'Mật khẩu mẫu: $_defaultDemoPassword (chạm vai trò để đăng nhập ngay)'
                      : 'Chạm để tự động điền email vai trò kiểm thử.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestAccountChip extends StatelessWidget {
  const _TestAccountChip({
    required this.account,
    required this.enabled,
    required this.onTap,
  });

  final _TestAccount account;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: account.email,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('test-account-${account.roleCode}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(account.icon, size: 16, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _testRoleLabel(context.l10n, account.roleCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
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

String _testRoleLabel(AppLocalizations l10n, String roleCode) =>
    switch (roleCode) {
      'citizen' => l10n.roleCitizen,
      'ubnd_tp' => l10n.roleUbndTp,
      'so_xd' => l10n.roleSoXd,
      'so_tnmt' => l10n.roleSoTnmt,
      'system_admin' => l10n.roleSystemAdmin,
      _ => roleCode,
    };
