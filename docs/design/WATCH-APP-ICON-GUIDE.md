# FLEXR watchOS App Icon Guide
**F-Power Icon for Apple Watch | Electric Blue #0A84FF**

---

## ⌚ Required Icon Sizes for watchOS

Apple Watch requires **16 different icon sizes** to support all watch models (38mm-49mm).

### watchOS App Icon Sizes

| Size (pt) | Scale | Pixels | Filename | Usage | Watch Model |
|-----------|-------|--------|----------|-------|-------------|
| 24x24 | @2x | **48x48** | `watch-icon-24@2x.png` | Notification Center | 38mm |
| 27.5x27.5 | @2x | **55x55** | `watch-icon-27.5@2x.png` | Notification Center | 42mm+ |
| 29x29 | @2x | **58x58** | `watch-icon-29@2x.png` | iPhone Settings | All |
| 29x29 | @3x | **87x87** | `watch-icon-29@3x.png` | iPhone Settings | All |
| 40x40 | @2x | **80x80** | `watch-icon-40@2x.png` | Home Screen | 38mm |
| 44x44 | @2x | **88x88** | `watch-icon-44@2x.png` | Home Screen | 40mm |
| 46x46 | @2x | **92x92** | `watch-icon-46@2x.png` | Home Screen | 41mm |
| 50x50 | @2x | **100x100** | `watch-icon-50@2x.png` | Home Screen | 44mm |
| 51x51 | @2x | **102x102** | `watch-icon-51@2x.png` | Home Screen | 45mm |
| 54x54 | @2x | **108x108** | `watch-icon-54@2x.png` | Home Screen | 49mm |
| 86x86 | @2x | **172x172** | `watch-icon-86@2x.png` | Short Look | 38mm |
| 98x98 | @2x | **196x196** | `watch-icon-98@2x.png` | Short Look | 42mm |
| 108x108 | @2x | **216x216** | `watch-icon-108@2x.png` | Short Look | 44mm |
| 117x117 | @2x | **234x234** | `watch-icon-117@2x.png` | Short Look | 45mm |
| 129x129 | @2x | **258x258** | `watch-icon-129@2x.png` | Short Look | 49mm |
| 1024x1024 | @1x | **1024x1024** | `watch-icon-1024.png` | App Store | All |

**Total: 16 PNG files needed**

---

## 🎨 watchOS Icon Design Differences

### Circular vs Square Icons

**IMPORTANT:** watchOS icons appear **CIRCULAR** (not square like iOS!)

**Design Considerations:**
1. **Safe Area:** Keep critical content within a **circular safe area**
2. **Corners:** Outer corners will be cropped (circular mask)
3. **Center-focused:** Put the F-Power mark in the center
4. **Test at 48px:** Smallest notification icon size

### Design Recommendations for F-Power on Watch

**Option 1: Circular Background**
- Black circular background
- Electric blue F-Power mark centered
- Cyan accent ring around edge (optional)
- Simpler than iPhone icon (remove details that won't show at 48px)

**Option 2: Just the Symbol**
- Electric blue F on black background
- No additional elements
- Maximum simplicity for tiny watch screen
- Let circular mask handle the shape

### Watch Icon vs iPhone Icon

| Aspect | iPhone Icon | Watch Icon |
|--------|-------------|------------|
| **Shape** | Rounded square | Circle |
| **Smallest size** | 58x58px (Settings) | 48x48px (Notifications) |
| **Complexity** | Can have detail | Keep simple |
| **Safe area** | 95% of canvas | 85% of canvas (circular) |
| **Background** | Solid recommended | Solid required |

---

## 📤 Export Process for watchOS

### Quick Method: appicon.co

1. Export your **circular watch icon design** at 1024x1024px
2. Go to [appicon.co](https://appicon.co)
3. Select **"watchOS"** (not iOS)
4. Upload your 1024x1024 PNG
5. Download watchOS icon pack
6. Place files in `ios/FLEXRWatch/Assets.xcassets/AppIcon.appiconset/`

### Manual Export

**For design tools:**
1. Create circular artboard at 1024x1024px
2. Place F-Power mark in center
3. Keep content within 85% safe area (circular)
4. Export all 16 sizes listed above
5. Save as PNG-24 (no transparency)

---

## 📁 File Placement

Place all watch icon files here:

```
ios/FLEXRWatch/Assets.xcassets/AppIcon.appiconset/
├── watch-icon-24@2x.png    (48x48px) ⚠️ SMALLEST - test this!
├── watch-icon-27.5@2x.png  (55x55px)
├── watch-icon-29@2x.png    (58x58px)
├── watch-icon-29@3x.png    (87x87px)
├── watch-icon-40@2x.png    (80x80px)
├── watch-icon-44@2x.png    (88x88px)
├── watch-icon-46@2x.png    (92x92px)
├── watch-icon-50@2x.png    (100x100px)
├── watch-icon-51@2x.png    (102x102px)
├── watch-icon-54@2x.png    (108x108px)
├── watch-icon-86@2x.png    (172x172px)
├── watch-icon-98@2x.png    (196x196px)
├── watch-icon-108@2x.png   (216x216px)
├── watch-icon-117@2x.png   (234x234px)
├── watch-icon-129@2x.png   (258x258px)
├── watch-icon-1024.png     (1024x1024px) ← App Store
└── Contents.json           (already configured ✅)
```

---

## ✅ watchOS Icon Checklist

- [ ] Design uses circular safe area (85% of canvas)
- [ ] Tested at 48x48px (notification icon) - F is readable
- [ ] No transparency (solid background required)
- [ ] Electric blue (#0A84FF) matches iPhone app
- [ ] Simplified compared to iPhone icon (less detail)
- [ ] All 16 PNG files exported at exact sizes
- [ ] Filenames match Contents.json exactly
- [ ] 1024x1024 icon perfect for App Store

---

## 🎯 Design Template

Here's a simple Figma/Sketch template setup:

```
Canvas: 1024x1024px
├── Circular mask (1024x1024 circle)
├── Safe area guide (870x870 circle, centered) ← Keep F-Power here
└── Background (black, 1024x1024)
```

**F-Power Placement:**
- Center the F symbol
- Scale to fit within 870px safe area
- Use electric blue (#0A84FF)
- Add cyan (#00D9FF) accent sparingly (or skip for simplicity)

---

## 🧪 Testing

**In Xcode:**
1. Open Watch scheme
2. Build and run on Watch simulator
3. Check all contexts:
   - Home screen (grid view)
   - List view
   - Notifications (critical - 48px)
   - iPhone Watch app (Settings)

**On Device:**
1. Install via TestFlight or development build
2. Test on actual Apple Watch
3. View in different watch faces
4. Check notification appearance

---

## 💡 Pro Tips for F-Power Watch Icon

**Keep It Simpler:**
- Reduce italic angle even more than iPhone (or make upright)
- Thicker strokes than iPhone version
- Consider: just "F" symbol, no "Power" text
- Circular background helps frame the F

**Test the 48px Icon:**
- This is displayed in notifications
- If the F isn't instantly recognizable, simplify further
- Consider removing cyan accent at this size

**Consistency with iPhone:**
- Use same electric blue (#0A84FF)
- Similar visual language (F-Power mark)
- But simpler execution for tiny watch screen

---

## 📊 Recommended Variations to Test

**Version A: Full F-Power Mark**
- Same as iPhone icon, circular crop
- Electric blue + cyan accent
- Test at 48px

**Version B: Simplified F-Power**
- Just the F symbol
- Electric blue only (no cyan)
- Thicker strokes
- More readable at 48px

**Version C: Maximum Simplicity**
- Bold F letter
- No italic (upright)
- Electric blue on black
- Guaranteed readable at 48px

**Recommendation:** Start with Version A, but be prepared to go with Version B if 48px test fails.

---

## 🚀 Quick Start

1. **Design circular watch icon** (1024x1024px, 85% safe area)
2. **Go to appicon.co**, select "watchOS"
3. **Upload and download** icon pack
4. **Copy PNGs** to `ios/FLEXRWatch/Assets.xcassets/AppIcon.appiconset/`
5. **Test in Xcode** - especially 48px notification icon
6. **Simplify if needed** (reduce details, thicker strokes)

---

## 🔗 Assets Already Set Up

I've already created:
- ✅ `Assets.xcassets` folder for FLEXRWatch
- ✅ `AppIcon.appiconset` with correct Contents.json
- ✅ `AccentColor.colorset` with electric blue (#0A84FF)

**You just need to export and drop in the 16 PNG files!**

---

**Remember:** watchOS icons are CIRCULAR and TINY (48px minimum). Keep it simple!
