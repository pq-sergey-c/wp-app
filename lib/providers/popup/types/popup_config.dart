import 'package:flutter/material.dart';
import 'package:wp_player/layout/popup/fragments/implementations/popup_loading.dart';
import 'package:wp_player/layout/popup/fragments/implementations/popup_network_issues.dart';
import 'package:wp_player/layout/popup/fragments/implementations/popup_notification.dart';
import 'package:wp_player/layout/popup/fragments/implementations/popup_yes_no.dart';

@immutable
sealed class PopupBaseConfig {
  final String title;
  final TextSpan message;

  /// Called when removed from stack due to navigation
  final void Function()? onForcedClosedCallback;

  const PopupBaseConfig({required this.title, required this.message, this.onForcedClosedCallback});

  Widget build({bool withBackgroundOverlay = false});
}

@immutable
class PopupNotificationConfig extends PopupBaseConfig {
  final String buttonText;
  final void Function() buttonCallback;

  const PopupNotificationConfig({
    required super.title,
    required super.message,
    required this.buttonText,
    required this.buttonCallback,
    super.onForcedClosedCallback,
  });

  @override
  Widget build({bool withBackgroundOverlay = false}) =>
      PopupNotification(this, withBackgroundOverlay: withBackgroundOverlay);
}

@immutable
class PopupYesNoConfig extends PopupBaseConfig {
  final String yesText;
  final String noText;
  final void Function() yesCallback;
  final void Function() noCallback;

  const PopupYesNoConfig({
    required super.title,
    required super.message,
    required this.yesText,
    required this.noText,
    required this.yesCallback,
    required this.noCallback,
    super.onForcedClosedCallback,
  });

  @override
  Widget build({bool withBackgroundOverlay = false}) => PopupYesNo(this, withBackgroundOverlay: withBackgroundOverlay);
}

@immutable
class PopupLoadingConfig extends PopupBaseConfig {
  const PopupLoadingConfig({required super.title, required super.message, super.onForcedClosedCallback});

  @override
  Widget build({bool withBackgroundOverlay = false}) =>
      PopupLoading(this, withBackgroundOverlay: withBackgroundOverlay);
}

@immutable
class PopupNetworkIssuesConfig extends PopupBaseConfig {
  const PopupNetworkIssuesConfig({required super.title, required super.message, super.onForcedClosedCallback});

  @override
  Widget build({bool withBackgroundOverlay = false}) =>
      PopupNetworkIssues(this, withBackgroundOverlay: withBackgroundOverlay);
}
