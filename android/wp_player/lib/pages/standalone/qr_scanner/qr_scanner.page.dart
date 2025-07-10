import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wp_player/hooks/core/router/use_on_page_pop.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';

/// Implies use of Imperative navigation and getting result from context.pop
class QrScannerPage extends HookConsumerWidget {
  const QrScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final isDetected = useRef<bool>(false);

    final squareSide = min(layout.screenHeight, layout.screenWidth) * 0.6;
    const borderConfig = BorderSide(color: AppColors.white, width: 4);

    final ticker = useSingleTickerProvider();
    final animationController = useAnimationController(vsync: ticker, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    final animation = Tween<double>(
      begin: -0.8,
      end: 0.8,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.linear));

    final scannerConfig = useMemoized(MobileScannerController.new, []);
    useOnPagePop(ref, onPop: scannerConfig.dispose);

    return Stack(
      children: [
        MobileScanner(
          controller: scannerConfig,
          onDetect: (BarcodeCapture capture) async {
            // used due several firing of onDetect
            // boolean flag is used due to one threaded async of dart
            // effectively atomic boolean flag - in this case
            if (!context.canPop() || isDetected.value) return;
            isDetected.value = true;

            final List<Barcode> barcodes = capture.barcodes;
            final result = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
            context.pop(result);
            await scannerConfig.dispose();
          },
        ),

        // Pseudo scanning box corners
        Center(
          child: SizedBox(
            width: squareSide,
            height: squareSide,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: animationController,
                  builder: (_, _) {
                    return Align(
                      alignment: Alignment(0, animation.value),
                      child: Container(height: 2, width: squareSide * 0.7, color: AppColors.cyanElectric),
                    );
                  },
                ),
                // top-right
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: squareSide / 4,
                    height: squareSide / 4,
                    decoration: const BoxDecoration(
                      border: Border(top: borderConfig, right: borderConfig),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
                    ),
                  ),
                ),
                // bottom-right
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: squareSide / 4,
                    height: squareSide / 4,
                    decoration: const BoxDecoration(
                      border: Border(bottom: borderConfig, right: borderConfig),
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
                    ),
                  ),
                ),
                // bottom-left
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    width: squareSide / 4,
                    height: squareSide / 4,
                    decoration: const BoxDecoration(
                      border: Border(bottom: borderConfig, left: borderConfig),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
                    ),
                  ),
                ),
                // top-left
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: squareSide / 4,
                    height: squareSide / 4,
                    decoration: const BoxDecoration(
                      border: Border(top: borderConfig, left: borderConfig),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
