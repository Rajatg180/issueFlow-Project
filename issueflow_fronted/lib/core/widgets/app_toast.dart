import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Jira-like toast using Overlay (so it matches theme and doesn't look like default SnackBar).
/// - Desktop/Web: top-right
/// - Mobile: bottom
class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final entry = OverlayEntry(
      builder: (ctx) {
        final c = Theme.of(ctx).extension<AppPalette>()!;

        final bg = isError ? const Color(0xFF7F1D1D) : c.surface2;
        final border = isError ? const Color(0xFFB91C1C) : c.border;

        return Positioned(
          top: isMobile ? null : 16,
          right: isMobile ? null : 16,
          left: isMobile ? 16 : null,
          bottom: isMobile ? 16 : null,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: isError ? const Color(0xFFFCA5A5) : c.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: c.textPrimary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    Future.delayed(duration, () => entry.remove());
  }
}
