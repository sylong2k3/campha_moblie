import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/locale/locale_controller.dart';
import '../../../app/theme/theme_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_config.dart';
import '../../../core/permissions/user_role.dart';
import '../../../core/permissions/user_role_l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../auth/presentation/auth_widgets.dart';

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
                        child: ListTile(
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
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '${l10n.versionLabel} ${ApiConfig.appVersion}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colors.onPrimary.withValues(alpha: 0.16),
            foregroundColor: colors.onPrimary,
            child: Text(
              user.initials,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: colors.onPrimary),
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
                  ).textTheme.titleLarge?.copyWith(color: colors.onPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.verified_user_outlined, size: 17),
                  label: Text(
                    user.roleName.isNotEmpty
                        ? user.roleName
                        : role.displayLabel(context.l10n),
                  ),
                  backgroundColor: colors.surfaceContainerLowest,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CivicBrand(),
          const SizedBox(height: 22),
          Text(
            context.l10n.profileGuestTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(context.l10n.profileGuestBody),
          const SizedBox(height: 18),
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    ),
  );
}
