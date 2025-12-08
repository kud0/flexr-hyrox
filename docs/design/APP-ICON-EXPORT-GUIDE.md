# FLEXR App Icon Export Guide
**F-Power Icon Design | Electric Blue #0A84FF**

---

## 📱 Required Icon Sizes for iOS

You need to export your F-Power icon design at these exact pixel dimensions:

### iPhone App Icon Sizes

| Size (pt) | Scale | Pixels | Filename | Usage |
|-----------|-------|--------|----------|-------|
| 20x20 | @2x | **40x40** | `icon-20@2x.png` | Notifications |
| 20x20 | @3x | **60x60** | `icon-20@3x.png` | Notifications |
| 29x29 | @2x | **58x58** | `icon-29@2x.png` | Settings (CRITICAL: Test readability!) |
| 29x29 | @3x | **87x87** | `icon-29@3x.png` | Settings |
| 40x40 | @2x | **80x80** | `icon-40@2x.png` | Spotlight |
| 40x40 | @3x | **120x120** | `icon-40@3x.png` | Spotlight |
| 60x60 | @2x | **120x120** | `icon-60@2x.png` | iPhone Home Screen |
| 60x60 | @3x | **180x180** | `icon-60@3x.png` | iPhone Home Screen |
| 1024x1024 | @1x | **1024x1024** | `icon-1024.png` | App Store (REQUIRED) |

**Total: 9 PNG files needed**

---

## 🎨 Design Specifications

### Your F-Power Icon Design

**Brand Colors:**
- **Primary:** Electric Blue `#0A84FF` (RGB: 10, 132, 255)
- **Accent:** Cyan `#00D9FF` (RGB: 0, 217, 255)
- **Background:** Black or dark gray for contrast

**Design Elements:**
- F-Power letterform with italic angle (~15°)
- Electric blue primary color
- Cyan accent/highlights
- Clean, minimal, athletic aesthetic

### Critical Design Considerations

**1. Small Size Readability (29x29 @ 58px)**
- The 58x58px Settings icon is the SMALLEST size
- Test your icon at this size - if the F isn't clearly readable, consider:
  - Reducing italic angle (make more upright)
  - Simplifying details
  - Increasing contrast
  - Thicker strokes

**2. Background**
- iOS icons appear on various backgrounds (light/dark mode, folders)
- Recommend: Dark background (black or very dark gray) for your icon
- Avoid transparent backgrounds (iOS will add white)

**3. Rounded Corners**
- iOS automatically applies rounded corners (continuous curve)
- DO NOT round corners in your export - iOS handles this
- Design edge-to-edge, corners will be masked

**4. No Text**
- Your F-Power symbol is perfect (icons should be symbolic, not text-heavy)
- Ensure the "F" is clearly recognizable as a letter/brand mark

---

## 📤 Export Process

### Option 1: Design Tool with Asset Catalog Export (Figma/Sketch)

**Figma:**
1. Install "iOS App Icon Export" plugin
2. Select your icon frame (1024x1024)
3. Run plugin to export all sizes automatically
4. Plugin generates all 9 files with correct names

**Sketch:**
1. Use "Sketch App Icon Template"
2. Place your design in the artboard
3. Export > Export All Sizes
4. Saves all required sizes

### Option 2: Manual Export (Any Design Tool)

**Step-by-step:**
1. Create your icon at **1024x1024px** (highest quality source)
2. Export each size listed above as PNG
3. Use exact filenames (e.g., `icon-20@2x.png`)
4. Ensure **NO transparency** (solid background)
5. Ensure **NO rounded corners** (iOS adds these)
6. Save as **PNG-24** (not PNG-8, not JPEG)

### Option 3: Online Icon Generator (Quick & Easy)

**Recommended Tools:**
- **appicon.co** - Upload 1024x1024, generates all sizes
- **makeappicon.com** - Same, free and reliable
- **icon.kitchen** - Google's tool, excellent quality

**Steps:**
1. Export your F-Power icon at **1024x1024px** as PNG
2. Upload to appicon.co
3. Download iOS icon pack
4. Extract ZIP to get all sizes

---

## 📁 File Placement

After exporting all icon files, place them here:

```
ios/FLEXR/Assets.xcassets/AppIcon.appiconset/
├── icon-20@2x.png    (40x40px)
├── icon-20@3x.png    (60x60px)
├── icon-29@2x.png    (58x58px) ⚠️ Test this size!
├── icon-29@3x.png    (87x87px)
├── icon-40@2x.png    (80x80px)
├── icon-40@2x.png    (120x120px)
├── icon-60@2x.png    (120x120px)
├── icon-60@3x.png    (180x180px)
├── icon-1024.png     (1024x1024px) ← App Store
└── Contents.json     (already configured ✅)
```

---

## ✅ Quality Checklist

Before finalizing your icons:

- [ ] Test 58x58px size - is the F clearly readable?
- [ ] Check contrast on light AND dark backgrounds
- [ ] Verify electric blue (#0A84FF) matches brand
- [ ] Ensure no rounded corners (iOS adds these)
- [ ] Confirm solid background (no transparency)
- [ ] All files are PNG-24 format
- [ ] Filenames exactly match Contents.json
- [ ] 1024x1024 icon looks perfect (used in App Store)

---

## 🎯 Testing Your Icon

**In Xcode:**
1. Open `FLEXR.xcodeproj`
2. Navigate to `Assets.xcassets > AppIcon`
3. Drag and drop each PNG into the corresponding slot
4. Build and run on simulator
5. Check icon in:
   - Home screen
   - Settings app (critical - 58px test)
   - Notifications
   - Spotlight search

**On Device:**
1. Install TestFlight build or development build
2. View icon on actual hardware
3. Test in various contexts (light/dark mode, folders)

---

## 🔧 Common Issues & Fixes

### Icon appears blurry
→ Ensure you exported at exact pixel dimensions (not scaled down from larger)

### Icon has white corners
→ You exported with transparency - iOS adds white background. Use solid color.

### Icon looks different on device vs simulator
→ Test on actual device - colors may appear different on OLED vs LCD

### Settings icon (58px) is unreadable
→ Simplify your design - reduce italic angle, thicker strokes, higher contrast

### Wrong colors
→ Check color profile - export as sRGB, not Display P3 or Adobe RGB

---

## 🎨 Design Tips for Your F-Power Icon

**What Makes a Great App Icon:**
1. **Instantly recognizable** at 58px (Settings size)
2. **Distinctive** from competitors (your electric blue does this!)
3. **Consistent** with brand (matches your blue brand perfectly ✅)
4. **Simple** - avoid excessive detail
5. **Memorable** - the F-Power mark is unique

**Your Icon Strengths:**
- ✅ Electric blue differentiates from Apple Fitness+ (green)
- ✅ F-Power symbol is unique and memorable
- ✅ Athletic/performance aesthetic matches HYROX
- ✅ Cyan accent adds energy and movement

**Consider Testing:**
- Reduce italic angle from ~15° to ~10° if 58px readability suffers
- Increase F stroke weight slightly for small sizes
- Test cyan accent visibility at 58px - may need more contrast

---

## 📊 Recommended Design Variations

Create 2-3 variations to test:

**Version A: Current Design**
- 15° italic angle
- Current stroke weight
- Cyan accent on F

**Version B: Optimized for Small Sizes**
- 10° italic angle (more upright)
- +20% thicker strokes
- Higher contrast cyan accent

**Version C: Maximum Readability**
- 5° italic angle (nearly upright)
- Bold strokes
- Simplified accent (or no accent)

**Test all three at 58px and choose the most readable while maintaining brand aesthetic.**

---

## 🚀 Quick Start (TL;DR)

1. **Export your F-Power icon at 1024x1024px** (PNG, solid background, no rounded corners)
2. **Go to appicon.co** and upload it
3. **Download iOS icon pack**
4. **Extract and copy all PNGs** to `ios/FLEXR/Assets.xcassets/AppIcon.appiconset/`
5. **Open in Xcode** and verify all slots are filled
6. **Build and test** - especially check 58px Settings icon

**That's it!** Your electric blue F-Power icon is ready to ship.

---

**Questions?** Test the 58px icon first - that's the hardest size to get right!
