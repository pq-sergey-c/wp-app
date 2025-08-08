import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
          Container(
            padding: EdgeInsetsGeometry.only(top: layout.getClampedHeight(percent: 1.5, min: 10)),
            width: layout.screenWidth,
            child: SvgPicture.asset(
              'assets/images/wavepaths_logo.svg',
              height: 44,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(themeMode.themeConfig.title, BlendMode.srcIn),
            ),
          ),

          layout.selectByScreenType(
            orElse: _informationOrElse(layout, infoEntriesParsed),
            desktop: _informationDesktop(amountOfRowsInDesktop, amountOfColumnsInDesktop, infoEntriesParsed, layout),
          ),

          ExternalLinkBox(
            text: TextSpan(
              text: "Create your Provider Wavepaths account for free ",
              children: [
                TextSpan(
                  text: "(No card details needed)",
                  style: TextStyle(fontSize: layout.getTextSize(TextSizes.xs)),
                ),
              ],
              style: TextStyle(fontSize: layout.getTextSize(TextSizes.sm)),
            ),
            externalLink: ExternalLinks.registerAccount.uri,
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

  static const List<({String title, TextSpan text})> _infoEntries = [
    (
      title: "What is a Provider?",
      text: TextSpan(
        text:
            "A Providers is anyone using Wavepaths to provide music to Listeners. Only Providers with a subscription can create and adapt sessions",
      ),
    ),
    (
      title: "What is a Listener?",
      text: TextSpan(
        text:
            "A Listener is anyone receiving music from a Provider. Listeners can play this music for free and without the need for a subscription",
      ),
    ),
    (
      title: "Only Streaming?",
      text: TextSpan(
        text:
            "Yes, this app only streams music. Starting and controlling sessions happens through the Provider’s account and within the browser only",
      ),
    ),
  ];
}
