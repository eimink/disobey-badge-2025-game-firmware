# Image Conversion for Badge Display

This guide explains how to convert images into MicroPython-compatible format for the Disobey Badge 2025.

> **⚠️ Important**: The badge requires **RGB565_I** (inverted) format for correct colors. If you see inverted colors (yellow→white, blue→orange, etc.), you're using the wrong format. The default settings handle this automatically.

## Quick Start

Use the Makefile task to convert images:

```bash
make convert_image SOURCE_IMAGE=your_image.png TARGET_PY=frozen_firmware/modules/images/boot.py
```

This automatically uses RGB565_I format with Burke dithering for correct color display.

## Table of Contents

- [Overview](#overview)
- [Display Specifications](#display-specifications)
- [Conversion Process](#conversion-process)
- [Using the Makefile Task](#using-the-makefile-task)
- [Manual Conversion](#manual-conversion)
- [Image Guidelines](#image-guidelines)
- [Dithering Options](#dithering-options)
- [Troubleshooting](#troubleshooting)

## Overview

The badge display uses a **320x170 pixel** color screen. Images are converted to a Python module containing binary data that can be loaded by the badge's display driver.

The badge supports three color formats:
- **RGB565_I** (16-bit, Inverted+BigEndian) - **Default, correct colors for badge hardware**
- **RGB565** (16-bit, standard) - May show inverted/incorrect colors
- **GS8** (8-bit RRRGGGBB) - Memory efficient, reduced color range

## Display Specifications

- **Resolution**: 320 x 170 pixels
- **Color Format**: RGB565_I (16-bit inverted, default) or RGB565 (16-bit standard) or GS8 (8-bit)
- **Orientation**: Landscape
- **File Format**: Python module with binary data

### Color Format Comparison

| Format | Bits/Pixel | Mode | Bytes for 320x170 | Color Depth | Best For |
|--------|------------|------|-------------------|-------------|----------|
| **RGB565_I** ✨ | 16-bit | 10 | ~108 KB | 65K colors | **Default - correct colors** |
| **RGB565** | 16-bit | 1 | ~108 KB | 65K colors | May show color inversion |
| **GS8** | 8-bit | 6 | ~54 KB | 256 colors | Memory-constrained |

**Default**: The badge uses **RGB565_I format** (inverted RGB565) with **Burke dithering** for correct color display. This format matches the badge hardware's color interpretation.

## Conversion Process

The conversion happens in two steps:

1. **Format Conversion**: Source image → PPM (Netpbm) format
2. **Python Generation**: PPM → Python module with image data

### Choosing the Right Format

The badge's current configuration uses the **16-bit driver** (`st7789_16bit`), which supports all three formats with automatic conversion:

**Use RGB565_I (16-bit inverted) when:**
- ✅ **Default choice** - provides correct colors on badge
- ✅ Yellow appears as yellow (not white/inverted)
- ✅ Colors match your original design

**Use RGB565 (16-bit standard) when:**
- ✅ Working with standard RGB565 tools/displays
- ✅ Testing compatibility with other hardware
- ⚠️ Note: May show inverted colors on badge (yellow→white, etc.)

**Use GS8 (8-bit) when:**
- ✅ You want to save memory (uses half the space)
- ✅ 256 colors is sufficient
- ✅ You need more images in limited flash space

**Default**: The Makefile defaults to **RGB565_I with Burke dithering** for correct color display on the badge hardware. RGB565_I uses inverted byte order which matches how the badge display interprets colors.

## Using the Makefile Task

### Basic Usage

```bash
make convert_image SOURCE_IMAGE=<input_file> TARGET_PY=<output_file>
```

This creates an **RGB565_I (16-bit inverted)** image with **Burke dithering** by default for correct colors on the badge.

### Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `SOURCE_IMAGE` | ✅ Yes | - | Path to source image (PNG, JPG, BMP, etc.) |
| `TARGET_PY` | ✅ Yes | - | Path to output Python file |
| `WIDTH` | ⬜ No | 320 | Target width in pixels |
| `HEIGHT` | ⬜ No | 170 | Target height in pixels |
| `DITHER` | ⬜ No | Burke | Dithering algorithm |
| `FORMAT` | ⬜ No | RGB565_I | Color format: `RGB565_I`, `RGB565`, or `GS8` |

### Examples

**Convert boot screen image (RGB565_I with Burke dithering - default):**
```bash
make convert_image \
  SOURCE_IMAGE=designs/boot_screen.png \
  TARGET_PY=frozen_firmware/modules/images/boot.py
```

**Convert with different dithering algorithm:**
```bash
make convert_image \
  SOURCE_IMAGE=photo.jpg \
  TARGET_PY=firmware/images/photo.py \
  DITHER=Atkinson
```

**Convert to standard RGB565 (if colors appear inverted):**
```bash
make convert_image \
  SOURCE_IMAGE=icon.png \
  TARGET_PY=firmware/images/icon.py \
  FORMAT=RGB565
```

**Convert to GS8 (8-bit) for smaller file size:**
```bash
make convert_image \
  SOURCE_IMAGE=icon.png \
  TARGET_PY=firmware/images/icon.py \
  FORMAT=GS8
```

**Convert without dithering:**
```bash
make convert_image \
  SOURCE_IMAGE=icon.png \
  TARGET_PY=firmware/images/icon.py \
  DITHER=None
```

**Convert with different dithering algorithm:**
```bash
make convert_image \
  SOURCE_IMAGE=photo.jpg \
  TARGET_PY=firmware/images/photo.py \
  DITHER=Burke
```

## Manual Conversion

If you need more control or want to understand the process:

### Step 1: Install ImageMagick

```bash
# In dev container or host system
apt-get update && apt-get install -y imagemagick
```

### Step 2: Convert to PPM Format

```bash
# Convert and resize in one step
convert your_image.png -resize 320x170! output.ppm
```

**Notes:**
- The `!` after dimensions forces exact size (ignores aspect ratio)
- Without `!`, it maintains aspect ratio and may not match desired dimensions
- Use `-resize 320x170` to maintain aspect ratio with max dimensions

### Step 3: Convert to MicroPython Format

**For RGB565_I (16-bit inverted, default - correct colors):**
```bash
python libs/micropython-micro-gui/utils/img_cvt.py \
  output.ppm \
  frozen_firmware/modules/images/boot.py \
  --rgb565 \
  --invert-rgb565 \
  --dither Burke
```

**For RGB565 (16-bit standard):**
```bash
python libs/micropython-micro-gui/utils/img_cvt.py \
  output.ppm \
  frozen_firmware/modules/images/boot.py \
  --rgb565 \
  --dither Burke
```

**For GS8 (8-bit):**
```bash
python libs/micropython-micro-gui/utils/img_cvt.py \
  output.ppm \
  frozen_firmware/modules/images/boot.py \
  --dither Atkinson
```

### Step 4: Clean Up

```bash
rm output.ppm
```

## Image Guidelines

### Recommended Image Properties

1. **Design for 320x170 pixels** from the start
2. **Use web-safe colors** - the display has limited color depth
3. **High contrast** - works better on small displays
4. **Avoid fine details** - may be lost in conversion
5. **Test with dithering** - some images look better with specific algorithms

### File Size Considerations

- RGB565 images take approximately `width × height × 2` bytes
- 320x170 image ≈ 108 KB
- Consider compression for multiple images
- Use simpler images to reduce flash usage

### Color Accuracy

**RGB565_I Format (16-bit inverted, recommended):**
- **5 bits for Red** (32 levels)
- **6 bits for Green** (64 levels)
- **5 bits for Blue** (32 levels)
- Total: **65,536 colors**
- Inverted and big-endian byte order
- **Correct color display on badge hardware**

**RGB565 Format (16-bit standard):**
- Same color depth as RGB565_I
- Standard byte order
- ⚠️ **May show inverted colors on badge** (use RGB565_I instead)

**GS8 Format (8-bit RRRGGGBB):**
- **3 bits for Red** (8 levels)
- **3 bits for Green** (8 levels)
- **2 bits for Blue** (4 levels)
- Total: **256 colors**
- More prone to banding, but uses half the memory

**Tip**: Use **RGB565_I with Burke dithering** (default) for accurate colors. Burke dithering provides a good balance between quality and color distribution.

**Color Inversion Issue**: If you see inverted colors (e.g., yellow appears white), you're using the wrong format. RGB565 shows inverted colors, while RGB565_I shows correct colors on the badge.

## Dithering Options

Dithering helps reduce color banding by distributing quantization errors to neighboring pixels.

### Available Algorithms

| Algorithm | Characteristics | Best For |
|-----------|----------------|----------|
| **Burke** ✨ | Balanced, moderate spreading | **Default - most images** |
| **Atkinson** | Lighter, preserves highlights | General purpose, photos |
| **Sierra** | Heavy, detailed spreading | Complex images |
| **FS** | Floyd-Steinberg, standard | Simple images |
| **None** | No dithering | Graphics, icons, logos |

### Choosing a Dithering Algorithm

**Default (Burke with RGB565_I):**
```bash
make convert_image SOURCE_IMAGE=photo.jpg TARGET_PY=output.py
```

**For graphics/logos (no dithering):**
```bash
make convert_image SOURCE_IMAGE=logo.png TARGET_PY=output.py DITHER=None
```

**For complex photos (heavy dithering):**
```bash
make convert_image SOURCE_IMAGE=photo.jpg TARGET_PY=output.py DITHER=Sierra
```

## Image Usage in Code

Once converted, use the image in your badge code:

```python
from images import boot as boot_image
from bdg.utils import blit
from gui.core.ugui import ssd

# Display the image at position (0, 0)
blit(ssd, boot_image, 0, 0)
```

The generated Python module contains:
- `rows` - Image height
- `cols` - Image width  
- `mode` - Color mode (1 = RGB565, 6 = GS8, 10 = RGB565_I)
- `data` - Binary image data

**Note**: While the badge display driver uses RGB565 mode (mode 1) internally, images should be converted to RGB565_I format (mode 10) for correct color display. The blit function automatically handles the compatibility between RGB565_I images and RGB565 displays.

## Where to Store Images

### For Core Badge Images (Built into Firmware)

Place in: `frozen_firmware/modules/images/`

These images are compiled into the firmware and cannot be changed without reflashing.

**Pros:**
- Always available
- No runtime file access needed
- Faster loading

**Cons:**
- Requires reflashing to update
- Increases firmware size

### For Development/Testing Images

Place in: `firmware/images/`

These images are accessible during development with mpremote mount.

**Pros:**
- Easy to update
- Quick testing
- No firmware rebuild needed

**Cons:**
- Not available in production firmware
- Slower access

## Common Image Locations

- **Boot Screen**: `frozen_firmware/modules/images/boot.py` (320x170)
- **Game graphics**: `firmware/badge/games/<game_name>/` (various sizes)
- **Icons**: `firmware/images/` (small, 16x16, 32x32, etc.)

## Troubleshooting

### ImageMagick Not Found

**Error:**
```
Error: ImageMagick 'convert' command not found
```

**Solution:**
```bash
# In dev container
apt-get update && apt-get install -y imagemagick

# Or on host machine
# Ubuntu/Debian:
sudo apt-get install imagemagick

# macOS:
brew install imagemagick
```

### Image Dimensions Don't Match

**Error:**
```
Warning: Image dimensions don't match expected size
```

**Solution:**
Force exact dimensions with `!`:
```bash
convert image.png -resize 320x170! output.ppm
```

### Image Too Large

**Error:**
Badge runs out of memory when loading image.

**Solution:**
1. Use smaller dimensions
2. Reduce color complexity
3. Move image to `frozen_firmware` (compiled in)
4. Use simpler image with less detail

### Colors Look Wrong

**Issue:** Colors appear different on badge than on computer.

**Solutions:**
1. Try different dithering algorithms
2. Adjust source image contrast/brightness
3. Test with `DITHER=None` to see actual color mapping
4. Remember RGB565 has limited color depth

### Conversion Fails

**Error:**
```
Error: img_cvt.py conversion failed
```

**Solutions:**
1. Check PPM file is valid: `file output.ppm` should show "Netpbm PPM"
2. Ensure output directory exists: `mkdir -p frozen_firmware/modules/images`
3. Check permissions on target directory
4. Try manual conversion to isolate the issue

### Wrong Colors or Display Issues

**Issue:** Image displays with incorrect colors or doesn't appear correctly.

**Solution 1 - Use RGB565_I format (default, fixes inverted colors):**
```bash
# Convert with default settings - this fixes color inversion
make convert_image \
  SOURCE_IMAGE=your_image.png \
  TARGET_PY=frozen_firmware/modules/images/boot.py
```

**Solution 2 - If colors still look wrong, try RGB565:**
```bash
# Try standard RGB565 instead
make convert_image \
  SOURCE_IMAGE=your_image.png \
  TARGET_PY=frozen_firmware/modules/images/boot.py \
  FORMAT=RGB565
```

**Solution 3 - Try different dithering algorithms:**
```bash
# Try Atkinson or other dithering
make convert_image \
  SOURCE_IMAGE=your_image.png \
  TARGET_PY=frozen_firmware/modules/images/boot.py \
  DITHER=Atkinson
```

**Solution 4 - Check your display driver:**
Check `hardware_setup.py` to see which driver you're using:
```python
from drivers.st7789.st7789_16bit import ST7789  # Supports RGB565/RGB565_I
# OR
from drivers.st7789.st7789_8bit import ST7789   # Supports GS8
```

**Solution 5 - Verify image mode:**
```python
# In your converted image Python file, check:
mode = 10  # RGB565_I (16-bit inverted) - default, correct colors
mode = 1   # RGB565 (16-bit standard) - may show inverted colors
mode = 6   # GS8 (8-bit)
```

## Advanced Topics

### Custom Image Sizes

For non-standard sizes (game sprites, icons):

```bash
make convert_image \
  SOURCE_IMAGE=sprite.png \
  TARGET_PY=firmware/sprites/player.py \
  WIDTH=32 \
  HEIGHT=32 \
  DITHER=None
```

### Batch Conversion

Convert multiple images:

```bash
#!/bin/bash
for img in designs/*.png; do
    basename=$(basename "$img" .png)
    make convert_image \
        SOURCE_IMAGE="$img" \
        TARGET_PY="firmware/images/${basename}.py"
done
```

### Testing Images Without Flashing

```bash
# Copy to firmware directory
make convert_image \
  SOURCE_IMAGE=test.png \
  TARGET_PY=firmware/images/test.py

# Test with mpremote
make dev_exec CMD='
from images import test
from bdg.utils import blit
from gui.core.ugui import ssd
blit(ssd, test, 0, 0)
ssd.show()
'
```

## References

- **img_cvt.py**: `libs/micropython-micro-gui/utils/img_cvt.py`
- **Dithering algorithms**: https://en.wikipedia.org/wiki/Floyd%E2%80%93Steinberg_dithering
- **Netpbm format**: https://en.wikipedia.org/wiki/Netpbm
- **RGB565 format**: https://en.wikipedia.org/wiki/High_color

## Examples Gallery

### Boot Screen (320x170)

Original boot screen shows the Disobey logo and badge information.

Location: `frozen_firmware/modules/images/boot.py`

### Game Sprites (Various Sizes)

Game sprites are typically smaller (16x16, 32x32, 64x64) and benefit from no dithering:

```bash
make convert_image \
  SOURCE_IMAGE=player_sprite.png \
  TARGET_PY=firmware/sprites/player.py \
  WIDTH=32 \
  HEIGHT=32 \
  DITHER=None
```

---

**Need help?** Check [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) or ask in the development channel.
