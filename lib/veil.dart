/// **veil** — selectively apply animated visual effects to a Flutter widget
/// subtree, with per-child opt-out via [Unveiled].
///
/// ## Core widgets
///
/// - [Veil] — wraps a subtree in an animated greyscale + optional colour
///   overlay effect.
/// - [Unveiled] — exempts a specific descendant from all [Veil] effects,
///   keeping it full-colour and undimmed.
///
/// ## Basic usage
///
/// ```dart
/// import 'package:veil/veil.dart';
///
/// Veil(
///   enable: isSoldOut,
///   greyOpacity: 1.0,
///   overlayOpacity: 0.35,
///   overlayColor: Colors.black,
///   child: ProductCard(
///     child: Column(
///       children: [
///         ProductImage(),   // greyscale + dimmed
///         Unveiled(         // full colour, not dimmed
///           child: PriceTag(),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
library veil;

export 'src/unveiled.dart' show Unveiled;
export 'src/veil.dart' show Veil;
