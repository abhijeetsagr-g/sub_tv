import 'package:flutter/material.dart';

/// Official pre-approved "Sign in with Google" button image from Google's
/// asset bundle: https://developers.google.com/identity/branding-guidelines
///
/// This is the **Dark** theme, show-text, square variant (@4x). The image
/// ships the branded look exactly — fill, 1px stroke and label in Google Sans
/// — so no custom chrome is layered on top. It's drawn at the standard 40dp
/// height; the rounded corners are baked into the asset (transparent PNG).
///
/// A previous iteration re-built the button from scratch (Material + label);
/// that's how `assets/image/google_icon.png` (the icon-only, text-less
/// variant) ended up embedded inside it, producing a button-in-button.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.pending = false,
  });

  /// Invoked on tap. Ignored while [pending].
  final VoidCallback onPressed;

  /// True while an interactive sign-in is in flight: overlays a spinner and
  /// blocks re-entry.
  final bool pending;

  /// Official dark "Sign in with Google" button. @4x keeps it sharp on every
  /// Android density bucket when drawn at [height].
  static const String _asset = 'assets/image/google_sign_in_button.png';

  /// Standard button height from Google's pre-approved assets.
  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !pending,
      label: 'Sign in with Google',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: pending ? null : onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Height fixed at the spec'd 40dp; width follows the asset's
                // aspect ratio so the label is never stretched.
                Image.asset(
                  _asset,
                  height: _height,
                  fit: BoxFit.contain,
                ),
                if (pending)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}