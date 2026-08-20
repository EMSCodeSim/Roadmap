import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shared brand wordmark used in headers.
///
/// Keeps the title fully visible on typical iPhone widths by allowing
/// scale-down instead of truncation.
class FirefighterRoadmapWordmark extends StatelessWidget {
  static const String title = 'Firefighter Roadmap';
  // Prefer the same raster that ships as the app launcher icon (known-good on iOS).
  static const String _primaryAssetPath = 'assets/icons/Roadmap.png';
  // Keep a secondary fallback for older builds.
  static const String _secondaryAssetPath = 'assets/icons/career_road_icon_v2.png';

  final Color? foregroundColor;
  final double iconSize;
  final TextStyle? textStyle;
  final double gap;

  const FirefighterRoadmapWordmark({
    super.key,
    this.foregroundColor,
    this.iconSize = 22,
    this.textStyle,
    this.gap = 10,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = foregroundColor ?? cs.onSurface;
    final effectiveTextStyle =
        textStyle ?? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.1, color: color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FirefighterRoadmapHeaderIcon(size: iconSize, tint: color),
        SizedBox(width: gap),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, maxLines: 1, softWrap: false, style: effectiveTextStyle),
          ),
        ),
      ],
    );
  }
}

/// Device-safe raster icon.
///
/// Uses a PNG from `assets/` (declared in pubspec) and falls back to a Material
/// icon if decoding fails on device.
class FirefighterRoadmapHeaderIcon extends StatelessWidget {
  final double size;
  final Color? tint;

  const FirefighterRoadmapHeaderIcon({super.key, this.size = 22, this.tint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = tint ?? cs.onSurface;

    // NOTE: iOS builds are case-sensitive and can fail silently when the asset
    // path doesn't match exactly. We:
    // 1) use a known-good, pubspec-declared PNG
    // 2) enforce explicit size constraints
    // 3) provide a secondary asset fallback
    // 4) provide a Material icon fallback with debug logging
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        FirefighterRoadmapWordmark._primaryAssetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'Header icon failed to load primary asset '
            '${FirefighterRoadmapWordmark._primaryAssetPath}: $error',
          );
          return Image.asset(
            FirefighterRoadmapWordmark._secondaryAssetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error2, stackTrace2) {
              debugPrint(
                'Header icon failed to load secondary asset '
                '${FirefighterRoadmapWordmark._secondaryAssetPath}: $error2',
              );
              return Icon(
                Icons.local_fire_department_outlined,
                size: size,
                color: color,
              );
            },
          );
        },
      ),
    );
  }
}
