import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/components/controls/external_link_box.dart';
import 'package:wp_player/constants/external_links.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class AdditionalInfo extends ConsumerWidget {
  const AdditionalInfo({required this.userRole, super.key});

  final UserRole userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (userRole == UserRole.listener) {
      return Text(
        "As a Listener you can stream music for free via the link or QR code received by your Provider",
        textAlign: TextAlign.center,
        style: TextStyle(color: themeMode.themeConfig.subtext),
      );
    }

    return Column(
      spacing: 18,
      children: [
        ExternalLinkBox(
          text: const TextSpan(text: "Start a new session"),
          externalLink: ExternalLinks.startNewSessionFromTemplates.uri,
        ),
        ExternalLinkBox(
          text: const TextSpan(text: "Or stream an active session"),
          externalLink: ExternalLinks.currentUserSessions.uri,
        ),
        ExternalLinkBox(
          text: const TextSpan(text: "Subscribe if you haven’t already"),
          externalLink: ExternalLinks.subscriptionsPage.uri,
        ),
      ],
    );
  }
}
