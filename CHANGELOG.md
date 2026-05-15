## 1.1.0

* Added `blurSigma` param to `Veil` — animated gaussian blur effect
* Added `UnveiledBlurMode` — controls per-child blur behaviour inside a `Veil`
  * `UnveiledBlurMode.none` — child renders completely sharp
  * `UnveiledBlurMode.inherit` — child inherits parent `Veil`'s blur sigma (default)
  * `UnveiledBlurMode.custom(sigma:)` — child uses independent custom sigma
* Blur animates in sync with greyscale via the same `AnimationController`
* `UnveiledBlurCustomMode` exported for type-checking (`is UnveiledBlurCustomMode`)
* Updated example app with blur sigma slider and per-child blur mode controls

## 1.0.1

* Fix: shorten pubspec description to meet pub.dev 180 character limit

## 1.0.0

* Initial release
* `Veil` — animated greyscale + colour overlay effect with `greyOpacity`,
  `overlayOpacity`, `overlayColor`, `duration`, `curve`
* `Unveiled` — per-child opt-out, keeps descendants full-colour and undimmed
* Crash-safe compositing via `pushColorFilter`, `pushOpacity`, `pushClipRect`
* Zero per-frame GC allocation: pre-allocated matrix buffer, cached
  `ColorFilter` and `Paint` objects
* Microtask-batched `Unveiled` notifications (N mounts = 1 repaint)
* Assertion-safe `isRepaintBoundary` (permanently `true`)
* Full Flutter Inspector support via `debugFillProperties`