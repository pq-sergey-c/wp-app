import 'package:flutter/widgets.dart';

@immutable
sealed class PopupContent {
  const PopupContent();

  factory PopupContent.text({required String title, required TextSpan message}) {
    return PopupTextContent(title: title, message: message);
  }

  factory PopupContent.widget({required Widget widget}) {
    return PopupWidgetContent(widget);
  }
}

@immutable
class PopupTextContent extends PopupContent {
  final String title;
  final TextSpan message;
  const PopupTextContent({required this.title, required this.message});
}

@immutable
class PopupWidgetContent extends PopupContent {
  final Widget widget;
  const PopupWidgetContent(this.widget);
}
