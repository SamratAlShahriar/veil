/// Controls how blur is applied to an `Unveiled` child inside a `Veil`
/// that has `blurSigma` set.
///
/// Pass this to `Unveiled.blurMode` to control per-child blur behaviour.
///
/// ### Example
///
/// ```dart
/// Veil(
///   enable: true,
///   blurSigma: 6.0,
///   child: Column(
///     children: [
///       ProductImage(),   // fully blurred
///
///       Unveiled(         // completely sharp — no blur
///         blurMode: UnveiledBlurMode.none,
///         child: PriceTag(),
///       ),
///
///       Unveiled(         // custom sigma — softer than parent
///         blurMode: UnveiledBlurMode.custom(sigma: 1.5),
///         child: StatusBadge(),
///       ),
///
///       Unveiled(         // inherits parent blurSigma (default)
///         blurMode: UnveiledBlurMode.inherit,
///         child: CategoryLabel(),
///       ),
///     ],
///   ),
/// )
/// ```
sealed class UnveiledBlurMode {
  const UnveiledBlurMode();

  /// The `Unveiled` child is rendered completely sharp — no blur applied.
  static const UnveiledBlurMode none = _NoneBlurMode();

  /// The `Unveiled` child inherits the parent `Veil`'s `blurSigma`.
  ///
  /// This is the default behaviour when `Unveiled.blurMode` is not specified.
  static const UnveiledBlurMode inherit = _InheritBlurMode();

  /// The `Unveiled` child uses a custom blur sigma, independent of the
  /// parent `Veil`'s `blurSigma`.
  ///
  /// [sigma] must be >= 0.0. A sigma of `0.0` is equivalent to [none].
  const factory UnveiledBlurMode.custom({required double sigma}) =
      UnveiledBlurCustomMode;
}

/// No blur applied — child renders completely sharp.
final class _NoneBlurMode extends UnveiledBlurMode {
  const _NoneBlurMode();
}

/// Inherits the parent Veil's blurSigma.
final class _InheritBlurMode extends UnveiledBlurMode {
  const _InheritBlurMode();
}

/// Custom blur sigma independent of the parent Veil.
///
/// Created via `UnveiledBlurMode.custom(sigma: value)`.
final class UnveiledBlurCustomMode extends UnveiledBlurMode {
  /// Creates an [UnveiledBlurCustomMode] with the given [sigma].
  const UnveiledBlurCustomMode({required this.sigma})
      : assert(sigma >= 0.0, 'sigma must be >= 0.0');

  /// The blur sigma to apply to this specific `Unveiled` child.
  final double sigma;
}
