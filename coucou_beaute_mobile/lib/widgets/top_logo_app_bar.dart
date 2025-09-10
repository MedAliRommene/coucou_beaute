import 'package:flutter/material.dart';

class TopLogoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  final bool showBack;

  const TopLogoAppBar(
      {super.key, this.onMenuPressed, this.actions, this.showBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFFFB3D9),
      foregroundColor: const Color(0xFF4A90E2),
      centerTitle: false,
      titleSpacing: 12,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF4A90E2)),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : const SizedBox.shrink(),
      title: SizedBox(
        height: 40,
        child: Image.asset(
          'assets/images/logo2.png',
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF4A90E2)),
          onPressed: onMenuPressed ?? () {},
        ),
        ...?actions,
      ],
    );
  }
}
