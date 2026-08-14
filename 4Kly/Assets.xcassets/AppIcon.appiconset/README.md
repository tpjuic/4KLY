# App Icon Assets

## Status: Placeholder — Icon images need to be added manually

The `Contents.json` is configured with all required macOS app icon sizes:

| Size | Scale | Filename needed |
|------|-------|-----------------|
| 16x16 | 1x | icon_16x16.png |
| 16x16 | 2x | icon_16x16@2x.png (32x32 px) |
| 32x32 | 1x | icon_32x32.png |
| 32x32 | 2x | icon_32x32@2x.png (64x64 px) |
| 128x128 | 1x | icon_128x128.png |
| 128x128 | 2x | icon_128x128@2x.png (256x256 px) |
| 256x256 | 1x | icon_256x256.png |
| 256x256 | 2x | icon_256x256@2x.png (512x512 px) |
| 512x512 | 1x | icon_512x512.png |
| 512x512 | 2x | icon_512x512@2x.png (1024x1024 px) |

## How to add the icon

1. Design a 1024x1024 icon following [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)
2. Export at each required size listed above as PNG files
3. Place the PNG files in this directory (`AppIcon.appiconset/`)
4. Update `Contents.json` to reference each file by adding a `"filename"` key to each entry

### macOS Icon Design Guidelines
- Use a rounded rectangle (squircle) shape — Xcode applies the mask automatically
- Design the icon at 1024x1024 and scale down
- Keep important content within the safe area (inset ~10% from edges)
- Use depth, detail, and texture appropriate for each size
- Avoid text in the icon unless it's a core part of the brand

## Tools for generating icon sizes
- [IconGenerator](https://github.com/nicklama/icon-generator) — CLI tool
- [AppIconMaker](https://appiconmaker.co) — Web tool
- Xcode: Drag a 1024x1024 image into the asset catalog and Xcode can auto-generate sizes
