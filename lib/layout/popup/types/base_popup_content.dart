/*
 * Counterpart of [PopupContent] and subclasses for internal usage of popup implementation (wrappers around counterpart)
 */

import 'package:flutter/widgets.dart';
import 'package:wp_player/providers/popup/types/popup_content.dart';

@immutable
sealed class BasePopupContent {
  const BasePopupContent();

  factory BasePopupContent.text({required PopupTextContent content, required Widget icon, Color? titleColor}) {
    return BasePopupTextContent(content: content, icon: icon, titleColor: titleColor);
  }

  factory BasePopupContent.widget({required PopupWidgetContent content}) {
    return BasePopupWidgetContent(content);
  }
}

@immutable
class BasePopupTextContent extends BasePopupContent {
  final PopupTextContent content;
  final Widget icon;
  final Color? titleColor;

  const BasePopupTextContent({required this.content, required this.icon, this.titleColor});
}

@immutable
class BasePopupWidgetContent extends BasePopupContent {
  final PopupWidgetContent content;
  const BasePopupWidgetContent(this.content);
}
