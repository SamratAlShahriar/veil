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