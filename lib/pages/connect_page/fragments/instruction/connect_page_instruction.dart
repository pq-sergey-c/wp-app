import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wp_player/pages/connect_page/fragments/instruction/fragments/connect_page_instruction_narrow_listener.dart';
import 'package:wp_player/pages/connect_page/fragments/instruction/fragments/connect_page_instruction_narrow_provider.dart';
// TODO: access imports
// import 'package:wp_player/pages/connect_page/fragments/instruction/fragments/connect_page_instruction_wide_listener.dart'; // if removed also delete file
// import 'package:wp_player/pages/connect_page/fragments/instruction/fragments/connect_page_instruction_wide_provider.dart'; // if removed also delete file
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class ConnectPageInstruction extends ConsumerWidget {
  const ConnectPageInstruction({required this.userRole, super.key});

  final UserRole userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);

    return userRole == UserRole.listener
        ? layout.selectByScreenType(
          desktop: const ConnectPageInstructionNarrowListener(),
          orElse: const ConnectPageInstructionNarrowListener(),
        )
        : layout.selectByScreenType(
          desktop: const ConnectPageInstructionNarrowProvider(),
          orElse: const ConnectPageInstructionNarrowProvider(),
        );
  }
}
