import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/locale/locale_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/error/crashlytics_service.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../../core/permissions/user_role.dart';
import '../../../core/permissions/user_role_l10n.dart';
import '../../auth/domain/session_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(sessionControllerProvider.notifier).bootstrap(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(pinned: true, title: Text(l10n.navProfile)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                sliver: SliverList.list(
                  children: [
                    if (session.isAuthenticated && session.user != null)
                      _AuthenticatedHeader(session: session)
                    else
                      const _GuestHeader(),
                    const SizedBox(height: 20),
                    if (session.isAuthenticated) ...[
                      _SectionLabel(l10n.profileAccount),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              key: const ValueKey('profile-notifications'),
                              leading: const _ProfileTileIcon(
                                icon: Icons.notifications_outlined,
                              ),
                              title: const Text('Thông báo'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                              onTap: () => context.push('/notifications'),
                            ),
                            const Divider(height: 1, indent: 56),
                            ListTile(
                              key: const ValueKey('profile-my-reports'),
                          leading: const _ProfileTileIcon(
                            icon: Icons.assignment_outlined,
                          ),
                          title: Text(l10n.myReports),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                          onTap: () => context.push('/reports/mine'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _SectionLabel(l10n.profilePreferences),
                    const SizedBox(height: 8),
                    const _PreferencesCard(),
                    const SizedBox(height: 20),
                    if (session.isAuthenticated) ...[
                      _SectionLabel(l10n.profileSecurity),
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const _ProfileTileIcon(
                                icon: Icons.password_outlined,
                              ),
                              title: Text(l10n.changePasswordTitle),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                              onTap: () =>
                                  context.push('/profile/change-password'),
                            ),
                            const Divider(),
                            ListTile(
                              key: const ValueKey('logout-tile'),
                              leading: Icon(
                                Icons.logout,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                l10n.logoutAction,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onTap: () => _confirmLogout(context, ref),
                            ),
                            const Divider(),
                            ListTile(
                              key: const ValueKey('delete-account-tile'),
                              leading: Icon(
                                Icons.person_remove_outlined,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                l10n.deleteAccountAction,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onTap: () => _confirmDeleteAccount(context, ref),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _SectionLabel(l10n.profileLegal),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const _ProfileTileIcon(
                              icon: Icons.privacy_tip_outlined,
                            ),
                            title: Text(l10n.privacyPolicyTitle),
                            trailing: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            onTap: () =>
                                _openUrl(context, ApiConfig.privacyPolicyUrl),
                          ),
                          const Divider(height: 1, indent: 56),
                          ListTile(
                            leading: const _ProfileTileIcon(
                              icon: Icons.description_outlined,
                            ),
                            title: Text(l10n.termsOfServiceTitle),
                            trailing: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            onTap: () =>
                                _openUrl(context, ApiConfig.termsOfServiceUrl),
                          ),
                        ],
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.25),
                        child: ListTile(
                          leading: Icon(
                            Icons.bug_report_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: const Text('Test Firebase Crashlytics'),
                          onTap: () {
                            final success = CrashlyticsService.testCrash();
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Firebase chưa kết nối (thiếu google-services.json hoặc GoogleService-Info.plist)',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${l10n.versionLabel} ${ApiConfig.appVersion}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logoutAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(sessionControllerProvider.notifier).logout();
    if (context.mounted) context.go('/map');
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccountAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(sessionControllerProvider.notifier).deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteAccountSuccess)),
        );
        context.go('/map');
      }
    } catch (_) {
      if (context.mounted) {
        context.go('/map');
      }
    }
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở liên kết: $urlString')),
        );
      }
    }
  }
}

class _AuthenticatedHeader extends StatelessWidget {
  const _AuthenticatedHeader({required this.session});
  final SessionState session;

  @override
  Widget build(BuildContext context) {
    final user = session.user!;
    final role = UserRole.fromApiValue(user.roleCode);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar with gradient ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: colors.onPrimary.withValues(alpha: 0.16),
              foregroundColor: colors.onPrimary,
              child: Text(
                user.initials,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          user.roleName.isNotEmpty
                              ? user.roleName
                              : role.displayLabel(context.l10n),
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestHeader extends StatelessWidget {
  const _GuestHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
        boxShadow: AppColors.cardShadow(Theme.of(context).brightness),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 32,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.profileGuestTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.profileGuestBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('profile-login'),
              onPressed: () => context.push('/auth/login'),
              icon: const Icon(Icons.login),
              label: Text(context.l10n.loginAction),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.push('/auth/register'),
              child: Text(context.l10n.registerAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends ConsumerWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const _ProfileTileIcon(icon: Icons.translate_rounded),
            title: Text(l10n.languageLabel),
            subtitle: Text(
              locale.languageCode == 'en'
                  ? l10n.languageEnglish
                  : l10n.languageVietnamese,
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => SafeArea(
                child: RadioGroup<String>(
                  groupValue: locale.languageCode,
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(Locale(value));
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile(
                        value: 'vi',
                        title: Text(l10n.languageVietnamese),
                      ),
                      RadioListTile(
                        value: 'en',
                        title: Text(l10n.languageEnglish),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Divider(indent: 64),
          ListTile(
            leading: const _ProfileTileIcon(icon: Icons.contrast_rounded),
            title: Text(l10n.themeLabel),
            subtitle: Text(switch (themeMode) {
              ThemeMode.light => l10n.themeLight,
              ThemeMode.dark => l10n.themeDark,
              ThemeMode.system => l10n.themeSystem,
            }),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              builder: (context) => SafeArea(
                child: RadioGroup<ThemeMode>(
                  groupValue: themeMode,
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(themeControllerProvider.notifier)
                        .setThemeMode(value);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile(
                        value: ThemeMode.system,
                        title: Text(l10n.themeSystem),
                      ),
                      RadioListTile(
                        value: ThemeMode.light,
                        title: Text(l10n.themeLight),
                      ),
                      RadioListTile(
                        value: ThemeMode.dark,
                        title: Text(l10n.themeDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTileIcon extends StatelessWidget {
  const _ProfileTileIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    ),
  );
}
