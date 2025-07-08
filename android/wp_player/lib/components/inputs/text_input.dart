import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

// Note: using ConsumerStatefulWidget instead of HookConsumerWidget due to optional external inputController
class TextInput extends ConsumerStatefulWidget {
  const TextInput({required this.labelText, this.inputController, super.key});

  final TextEditingController? inputController;
  final String labelText;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TextInput();
}

class _TextInput extends ConsumerState<TextInput> {
  late final TextEditingController inputController;
  late final bool usesExternalController;
  bool hasText = false;

  @override
  void initState() {
    super.initState();
    usesExternalController = widget.inputController != null;
    inputController = widget.inputController ?? TextEditingController();
    hasText = inputController.text.isNotEmpty;

    inputController.addListener(_inputControllerListener);
  }

  @override
  void dispose() {
    inputController.removeListener(_inputControllerListener);
    if (!usesExternalController) inputController.dispose();
    super.dispose();
  }

  void _inputControllerListener() {
    final hasTextListenerValue = inputController.text.isNotEmpty;
    if (hasTextListenerValue != hasText) setState(() => hasText = hasTextListenerValue);
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(responsiveLayoutProvider);
    final textHeight = layout.getTextSize(TextSizes.normal);

    return LayoutBuilder(
      builder: (context, constraints) {
        final verticalPadding = (constraints.maxHeight - textHeight * 1.5) / 2;

        return TextField(
          controller: inputController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
            labelText: widget.labelText,
            labelStyle: TextStyle(
              fontVariations: [FontVariationWeight.w400()],
              letterSpacing: -1,
              fontSize: textHeight,
            ),
            suffixIcon:
                hasText
                    ? Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          inputController.clear();
                        },
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                    )
                    : null,
          ),
          style: TextStyle(fontVariations: [FontVariationWeight.w500()], fontSize: textHeight),
        );
      },
    );
  }
}
