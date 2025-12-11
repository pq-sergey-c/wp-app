import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:wp_player/components/inputs/text_input.dart';

class LinkInput extends StatefulWidget {
  const LinkInput({
    required this.labelText,
    this.inputController,
    this.onSubmitted,
    this.schemas = const <RegExp>[],
    this.trailingActions = const <Widget>[],
    super.key,
  });

  final TextEditingController? inputController;
  final String labelText;
  final ValueChanged<String>? onSubmitted;
  final List<RegExp> schemas;
  final List<Widget> trailingActions;

  @override
  State<LinkInput> createState() => _LinkInputState();
}

class _LinkInputState extends State<LinkInput> {
  late final TextEditingController _controller;
  late final bool _usesExternalController;
  late final FocusNode _focusNode;
  bool _clipboardCheckedForCurrentFocus = false;

  @override
  void initState() {
    super.initState();
    _usesExternalController = widget.inputController != null;
    _controller = widget.inputController ?? TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    if (!_usesExternalController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _clipboardCheckedForCurrentFocus = false;
      return;
    }

    if (_clipboardCheckedForCurrentFocus) return;
    _clipboardCheckedForCurrentFocus = true;

    // Pull a supported link from the clipboard once the field gains focus.
    scheduleMicrotask(() async {
      if (!mounted || !_focusNode.hasFocus) return;

      final clipboardLink = await _extractLinkFromClipboard();
      if (clipboardLink == null) return;
      if (_controller.text.trim().isNotEmpty) return;
      if (!mounted || !_focusNode.hasFocus) return;

      _controller
        ..text = clipboardLink
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: clipboardLink.length),
        );
    });
  }

  Future<String?> _extractLinkFromClipboard() async {
    if (widget.schemas.isEmpty) return null;

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final rawText = data?.text?.trim();
    if (rawText == null || rawText.isEmpty) return null;

    for (final schema in widget.schemas) {
      final match = schema.firstMatch(rawText);
      if (match != null) return match.group(0);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextInput(
      inputController: _controller,
      labelText: widget.labelText,
      onSubmitted: widget.onSubmitted,
      focusNode: _focusNode,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      textInputAction: TextInputAction.done,
      trailingActions: widget.trailingActions,
    );
  }
}
