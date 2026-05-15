/// **veil** — selectively apply animated visual effects to a Flutter widget
/// subtree, with per-child opt-out via `Unveiled`.
///
/// ## Core widgets
///
/// - `Veil` — wraps a subtree in an animated greyscale, blur, and optional
///   colour overlay effect.
/// - `Unveiled` — exempts a specific descendant from `Veil` greyscale and
///   overlay effects. Blur is controlled per-child via `UnveiledBlurMode`.
/// - `UnveiledBlurMode` — controls blur behaviour for each `Unveiled` child.
///
/// ## Basic usage
///
/// ```dart
/// import 'package:veil/veil.dart';
///
/// Veil(
///   enable: isSoldOut,
///   greyOpacity: 1.0,
///   blurSigma: 4.0,
///   overlayOpacity: 0.35,
///   overlayColor: Colors.black,
///   child: ProductCard(
///     child: Column(
///       children: [
///         ProductImage(),                            // greyscale + blur + dimmed
///         Unveiled(                                 // sharp, full colour, not dimmed
///           blurMode: UnveiledBlurMode.none,
///           child: PriceTag(),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
library;

export 'src/unveiled.dart' show Unveiled;
export 'src/unveiled_blur_mode.dart'
    show UnveiledBlurMode, UnveiledBlurCustomMode;
export 'src/veil.dart' show Veil;
