import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.pending = false,
  });

  final VoidCallback onPressed;
  final bool pending;

  static const double _height = 40;

  static const Color _fill = Color(0xFF131314);
  static const Color _stroke = Color(0xFF8E918F);
  static const Color _labelColor = Color(0xFFE3E3E3);

  @override
  Widget build(BuildContext context) {
    const label = Text(
      'Sign in with Google',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _labelColor,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    );

    final leading = pending
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _labelColor,
            ),
          )
        : Image.asset('assets/image/google_icon.png');

    return Material(
      color: _fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: _stroke, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: pending ? null : onPressed,
        child: Semantics(
          button: true,
          label: 'Sign in with Google',
          child: SizedBox(
            height: _height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 12), // 12px before the G.
                leading,
                const SizedBox(width: 10), // 10px after the G.
                label,
                const SizedBox(width: 12), // 12px after the label.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
