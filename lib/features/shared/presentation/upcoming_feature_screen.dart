import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

class UpcomingFeatureScreen extends StatelessWidget {
  const UpcomingFeatureScreen({
    super.key,
    required this.titleBuilder,
    required this.descriptionBuilder,
    required this.icon,
    required this.sprintLabel,
  });

  factory UpcomingFeatureScreen.reports() => UpcomingFeatureScreen(
    titleBuilder: (context) => context.l10n.navReports,
    descriptionBuilder: (context) => context.l10n.reportsIntro,
    icon: Icons.campaign_outlined,
    sprintLabel: 'SPRINT 5',
  );

  factory UpcomingFeatureScreen.news() => UpcomingFeatureScreen(
    titleBuilder: (context) => context.l10n.navNews,
    descriptionBuilder: (context) => context.l10n.newsIntro,
    icon: Icons.newspaper_outlined,
    sprintLabel: 'SPRINT 2',
  );

  factory UpcomingFeatureScreen.documents() => UpcomingFeatureScreen(
    titleBuilder: (context) => context.l10n.navDocuments,
    descriptionBuilder: (context) => context.l10n.documentsIntro,
    icon: Icons.folder_copy_outlined,
    sprintLabel: 'SPRINT 2',
  );

  final String Function(BuildContext) titleBuilder;
  final String Function(BuildContext) descriptionBuilder;
  final IconData icon;
  final String sprintLabel;

  @override
  Widget build(BuildContext context) {
    final title = titleBuilder(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: colors.primaryFixed,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(icon, size: 46, color: colors.onPrimaryFixed),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    descriptionBuilder(context),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(sprintLabel),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.featureUpcomingBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
