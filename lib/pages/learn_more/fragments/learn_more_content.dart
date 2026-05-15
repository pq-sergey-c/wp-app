import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/controls/external_link_box.dart';
import 'package:wp_player/constants/external_links.dart';
import 'package:wp_player/providers/responsive_layout/fragments/responsive_layout_model.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class LearnMoreContent extends HookConsumerWidget {
  const LearnMoreContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    final infoEntriesParsed =
        _infoEntries
            .map(
              (entry) => (
                title: Text(
                  entry.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontVariations: [FontVariationWeight.w700()],
                    fontSize: layout.selectByScreenType(
                      desktop: layout.getTextSize(TextSizes.xl2),
                      orElse: layout.getTextSize(TextSizes.xl),
                    ),
                  ),
                ),
                text: Text.rich(
                  entry.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: layout.selectByScreenType(
                      mobile: layout.getTextSize(TextSizes.xs),
                      tablet: layout.getTextSize(TextSizes.xs),
                      desktop: layout.getTextSize(TextSizes.normal),
                    ),
                    color: themeMode.themeConfig.subtext,
                  ),
                ),
              ),
            )
            .toList();

    const amountOfColumnsInDesktop = 2;
    final amountOfRowsInDesktop =
        _infoEntries.length ~/ amountOfColumnsInDesktop + (_infoEntries.length & amountOfColumnsInDesktop == 0 ? 0 : 1);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          layout.selectByScreenType(
            orElse: _informationOrElse(layout, infoEntriesParsed),
            desktop: _informationDesktop(amountOfRowsInDesktop, amountOfColumnsInDesktop, infoEntriesParsed, layout),
          ),
          Padding(
            padding: EdgeInsets.only(top: layout.getClampedHeight(percent: 4, min: 24)),
            child: ExternalLinkBox(
            text: TextSpan(
              text: "Create your Provider Wavepaths account for free ",
              children: [
                TextSpan(
                  text: "(No card details needed)",
                  style: TextStyle(fontSize: layout.getTextSize(TextSizes.xs2)),
                ),
              ],
              style: TextStyle(fontSize: layout.getTextSize(TextSizes.xs)),
            ),
            externalLink: ExternalLinks.registerAccount.uri,
            ),
          ),
        ],
      ),
    );
  }

  Column _informationOrElse(ResponsiveLayout layout, List<({Text text, Text title})> infoEntriesParsed) {
    return Column(
      spacing: layout.getClampedHeight(percent: 6),
      children:
          infoEntriesParsed
              .map(
                (entry) => Column(spacing: layout.getTextSize(TextSizes.normal), children: [entry.title, entry.text]),
              )
              .toList(),
    );
  }

  Column _informationDesktop(
    int amountOfRowsInDesktop,
    int amountOfColumnsInDesktop,
    List<({Text text, Text title})> infoEntriesParsed,
    ResponsiveLayout layout,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 50,
      children: List.generate(amountOfRowsInDesktop, (row) {
        final start = row * amountOfColumnsInDesktop;
        final end = min(start + amountOfRowsInDesktop, infoEntriesParsed.length);
        return Column(
          spacing: layout.getTextSize(TextSizes.xs2),
          children: [
            Row(
              spacing: layout.getClampedWidth(percent: 5),
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  infoEntriesParsed
                      .getRange(start, end)
                      .map((entry) => SizedBox(width: layout.getClampedWidth(percent: 40), child: entry.title))
                      .toList(),
            ),
            Row(
              spacing: layout.getClampedWidth(percent: 5),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  infoEntriesParsed
                      .getRange(start, end)
                      .map((entry) => SizedBox(width: layout.getClampedWidth(percent: 40), child: entry.text))
                      .toList(),
            ),
          ],
        );
      }),
    );
  }

  static final List<({String title, TextSpan text})> _infoEntries = [
    (
      title: "What is a Provider?",
      text: const TextSpan(
        text:
            "A Providers is anyone using Wavepaths to provide music to Listeners. Only Providers with a subscription can create and adapt sessions",
      ),
    ),
    (
      title: "What is a Listener?",
      text: const TextSpan(
        text:
            "A Listener is anyone receiving music from a Provider. Listeners can play this music for free and without the need for a subscription",
      ),
    ),
    (
      title: "Only Streaming?",
      text: TextSpan(
        text:
            "Yes, this app only streams music. Starting sessions happens through the Provider’s account and ",
        children: [
          TextSpan(text: "within the browser", style: TextStyle(fontVariations: [FontVariationWeight.w700()])),
        ],
      ),
    ),    (
      title: "When running Live sessions\n(Real-time)",
      text: TextSpan(
        text:
            "Pause and play controls are available within the app, while advanced controls are accessible only in the browser. You can keep the browser window open during your session, or click \"",
        children: [
          TextSpan(text: "Advanced controls in browser", style: TextStyle(fontVariations: [FontVariationWeight.w700()])),
          const TextSpan(text: "\" in the app at any time after starting the session."),
        ],
      ),
    ),
    (
      title: "When pre-recorded sessions\n(Playback-only / Offline)",
      text: const TextSpan(
        text:
            "Pause and play controls are available within the app. To enable track skipping, we recommend either running sessions in Live mode or streaming the pre-recorded session directly in the browser instead.",
      ),
    ),  ];
}
