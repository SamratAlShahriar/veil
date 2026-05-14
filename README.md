# veil

Selectively apply animated visual effects to a Flutter widget subtree, with per-child opt-out via `Unveiled`.

[![pub package](https://img.shields.io/pub/v/veil.svg)](https://pub.dev/packages/veil)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Preview

![veil demo](https://raw.githubusercontent.com/SamratAlShahriar/veil/main/screenshots/demo.gif)

## Features

- **Animated greyscale** — smooth toggle with configurable duration and curve
- **Colour overlay** — dim or tint on top of the greyscale, also animated
- **Selective opt-out** — wrap any descendant in `Unveiled` to keep it full-colour and undimmed, even mid-animation
- **Configurable overlay colour** — black dim, warm amber, cool blue, anything
- **Crash-safe** — uses Flutter compositing primitives (`pushColorFilter`, `pushOpacity`, `pushClipRect`), never raw `canvas.saveLayer` / `restore`
- **Zero GC pressure** — pre-allocated matrix buffer, cached `ColorFilter` and `Paint` per render object
- **Assertion-safe** — `isRepaintBoundary` is permanently `true`, satisfying Flutter's `PipelineOwner.flushPaint` invariant

---

## Getting started

```yaml
dependencies:
  veil: ^1.0.0
```

```dart
import 'package:veil/veil.dart';
```

---

## Usage

### Basic greyscale

```dart
Veil(
  enable: isSoldOut,
  child: ProductCard(),
)
```

### Partial greyscale

```dart
Veil(
  enable: isDisabled,
  greyOpacity: 0.6,   // 60% grey, 40% colour retained
  child: ProductCard(),
)
```

### With overlay

```dart
Veil(
  enable: isSoldOut,
  greyOpacity: 1.0,
  overlayOpacity: 0.35,
  overlayColor: Colors.black,  // default
  child: ProductCard(),
)
```

### Custom tint colour

```dart
// Warm amber — "out of season"
Veil(
  enable: isOffSeason,
  greyOpacity: 0.6,
  overlayOpacity: 0.25,
  overlayColor: Colors.orange,
  child: ProductCard(),
)

// Cool blue — "coming soon"
Veil(
  enable: isComingSoon,
  greyOpacity: 0.8,
  overlayOpacity: 0.3,
  overlayColor: Color(0xFF1A237E),
  child: ProductCard(),
)
```

### Selective opt-out with Unveiled

```dart
Veil(
  enable: isSoldOut,
  greyOpacity: 1.0,
  overlayOpacity: 0.35,
  child: ProductCard(
    child: Column(
      children: [
        ProductImage(),       // greyscale + dimmed ✓
        ProductTitle(),       // greyscale + dimmed ✓
        Unveiled(             // full colour, not dimmed ✓
          child: PriceTag(),
        ),
        Unveiled(             // full colour, not dimmed ✓
          child: AddToCartButton(),
        ),
      ],
    ),
  ),
)
```

### Custom animation

```dart
Veil(
  enable: isDisabled,
  duration: Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
  child: Card(),
)
```

---

## API reference

### Veil

| Property | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | The subtree to apply effects to |
| `enable` | `bool` | `true` | Activates the veil effects |
| `greyOpacity` | `double` | `1.0` | Greyscale intensity (0.0–1.0) |
| `overlayOpacity` | `double` | `0.0` | Overlay opacity (0.0–1.0) |
| `overlayColor` | `Color` | `Color(0xFF000000)` | Overlay tint colour (alpha ignored) |
| `duration` | `Duration` | `350ms` | Toggle animation duration |
| `curve` | `Curve` | `Curves.easeInOut` | Toggle animation curve |

### Unveiled

| Property | Type | Description |
|---|---|---|
| `child` | `Widget` | Widget to exempt from all Veil effects |

---

## How it works

`Veil` uses a custom `RenderObject` (`RenderVeil`) that paints in three steps:

1. **Greyscale** — the entire subtree is painted through a `ColorFilterLayer` using the ITU-R BT.709 luminance matrix
2. **Overlay** — a solid colour rect is painted at the configured opacity via `OpacityLayer`
3. **Unveiled overdraw** — each `Unveiled` child is re-painted on top of both layers — unfiltered and undimmed — clipped to its own bounds

All compositing uses Flutter's own layer primitives rather than raw `canvas.saveLayer` / `restore`, which prevents the `"native peer has been collected"` crash that occurs when a child `RepaintBoundary` is composited mid-paint.

---

## License

MIT — see [LICENSE](LICENSE)
