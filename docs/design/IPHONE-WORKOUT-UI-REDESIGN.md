# iPhone Workout UI Redesign Proposal
## Apple Fitness+ Aesthetic for Large Screen

---

## Problem Statement

The current iPhone workout UI is a direct copy of the Watch app interface, which was designed for a small 1.7" screen. This doesn't take advantage of the iPhone's significantly larger display (6.1" - 6.7").

**Issues with current approach:**
- TabView with 4 swipeable pages wastes horizontal space
- Cramped metrics that could be larger and more readable
- User has to swipe between pages to see different metrics
- Doesn't feel premium on the larger screen
- Wastes the benefit of having a big, beautiful display

**Goal:**
Design a workout UI that uses the Apple Fitness+ aesthetic but is **optimized for the iPhone's large screen**, showing more information at once while maintaining clarity and focus.

---

## Design Philosophy

### Apple Fitness+ Style Means:
- **Clean, focused design** - Not cluttered, but uses space intelligently
- **Large, readable metrics** - Premium typography
- **Dark mode first** - Pure black backgrounds with vibrant accents
- **Smooth animations** - Polished transitions and updates
- **Contextual information** - Right info at right time
- **Haptic feedback** - Physical confirmation of actions

### iPhone Large Screen Advantages:
- **6.1" - 6.7" display** vs 1.7" Watch
- **Portrait orientation** - Vertical space for stacking information
- **Better readability** - Can show more metrics simultaneously
- **Richer interactions** - Tap, long-press, swipe gestures
- **Better graphs** - Room for real-time pace/HR charts

---

## Proposed Layout Structure

### Main Workout View (Single Scrollable Page)

```
┌─────────────────────────────────────────────────┐
│  [Status Bar - translucent]                     │  ← iOS status bar
├─────────────────────────────────────────────────┤
│                                                  │
│  SEGMENT HEADER (Fixed at top)                  │  ← Current segment info
│  ┌────────────────────────────────────────────┐ │
│  │  Run 1 • 1000m                        1/8  │ │
│  │  Target: 4:45-5:00/km                      │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  PRIMARY METRIC (Huge)                          │  ← Main focus
│  ┌────────────────────────────────────────────┐ │
│  │                                            │ │
│  │              5:42                          │ │  ← 120pt font
│  │         elapsed time                       │ │
│  │                                            │ │
│  │          [progress bar]                    │ │
│  │           650m / 1000m                     │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  LIVE METRICS GRID (2x2)                        │  ← Key metrics visible
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Current Pace │  │  Heart Rate  │            │
│  │              │  │              │            │
│  │   4:52/km    │  │   168 bpm    │            │  ← 36pt fonts
│  │   ▼ 0:08     │  │   Zone 4     │            │
│  └──────────────┘  └──────────────┘            │
│  ┌──────────────┐  ┌──────────────┐            │
│  │   Distance   │  │   Calories   │            │
│  │              │  │              │            │
│  │    650 m     │  │     145      │            │
│  │   65% done   │  │              │            │
│  └──────────────┘  └──────────────┘            │
│                                                  │
│  HEART RATE GRAPH (Compact)                     │  ← Last 5 minutes
│  ┌────────────────────────────────────────────┐ │
│  │  180│         ╭╮                           │ │
│  │     │    ╭──╮╭╯╰╮                          │ │
│  │  150│╮─╮╭╯  ╰╯  ╰╮                         │ │
│  │     │╰─╯        ╰───                       │ │
│  │  120└──────────────────────────           │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  NEXT SEGMENT PREVIEW                           │  ← What's coming
│  ┌────────────────────────────────────────────┐ │
│  │  Up Next: SkiErg 1000m                     │ │
│  │  Target: <4:30                             │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ACTIONS (Floating Bottom)                      │  ← Controls
│  ┌────────────┐  ┌────────────┐  ┌───────────┐ │
│  │   Pause    │  │    Next    │  │    End    │ │
│  └────────────┘  └────────────┘  └───────────┘ │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## Section Breakdown

### 1. Segment Header (Fixed)
**Position:** Top of screen, stays visible while scrolling

```swift
┌────────────────────────────────────────────────┐
│  🏃 Run 1 • 1000m                         1/8  │
│  Target: 4:45-5:00/km                          │
│  [────────────●────────────] 65%               │  ← Progress bar
└────────────────────────────────────────────────┘
```

**Content:**
- Segment type icon + name
- Target (distance/reps/time)
- Segment counter (1/8)
- Progress bar
- Compact, info-dense but readable

**Design:**
- Height: 80pt
- Background: Translucent dark blur
- Typography: 20pt semibold for name, 15pt for target
- Apple green accent (#30D158) for progress

---

### 2. Primary Metric (Large Display)
**Position:** Just below header, hero section

```swift
┌────────────────────────────────────────────────┐
│                                                │
│                   5:42                         │  ← 120pt
│              elapsed time                      │  ← 17pt gray
│                                                │
│  [█████████████████████░░░░░░░░░░]            │  ← Progress
│           650m / 1000m                         │  ← 17pt
│                                                │
└────────────────────────────────────────────────┘
```

**What to show:**
- **For timed segments:** Elapsed time
- **For distance segments:** Current distance
- **For rep segments:** Reps completed
- **For stations:** Elapsed time

**Design:**
- Metric: 120pt SF Pro Rounded Medium with tabular nums
- Label: 17pt gray
- Progress bar: 8pt height, rounded, Apple green
- White text on black background for maximum contrast

---

### 3. Live Metrics Grid (2x2)
**Position:** Below primary metric

```swift
┌──────────────────┐  ┌──────────────────┐
│  Current Pace    │  │   Heart Rate     │
│                  │  │                  │
│    4:52/km       │  │     168 bpm      │  ← 36pt
│    ▼ 0:08        │  │     Zone 4       │  ← Trend/context
└──────────────────┘  └──────────────────┘
┌──────────────────┐  ┌──────────────────┐
│    Distance      │  │    Calories      │
│                  │  │                  │
│     650 m        │  │      145         │
│    65% done      │  │                  │
└──────────────────┘  └──────────────────┘
```

**Design:**
- Card style: Dark gray (#1C1C1E), 12pt corner radius
- Padding: 16pt internal
- Spacing: 12pt between cards
- Metric value: 36pt SF Pro Rounded Medium
- Label: 13pt gray, all caps
- Trend indicators: Small colored text/arrows

**Content adapts by segment type:**
- **Run segments:** Current pace, avg pace, distance, HR
- **Station segments:** Current time, target time/reps, HR, calories
- **Transition:** Next segment, rest time, HR recovery, instructions

---

### 4. Heart Rate Graph (Optional, Collapsible)
**Position:** Below metrics grid

```swift
┌────────────────────────────────────────────────┐
│  HEART RATE - Last 5 Minutes                   │
│  180│         ╭╮                                │
│     │    ╭──╮╭╯╰╮                               │
│  150│╮─╮╭╯  ╰╯  ╰╮                              │
│     │╰─╯        ╰───                            │
│  120└──────────────────────────────            │
│                                                 │
│  Zones: Z2 ████ 45%   Z3 ███ 35%   Z4 ██ 20%  │
└────────────────────────────────────────────────┘
```

**Design:**
- Height: 180pt
- Apple green line graph
- Zone background shading (subtle)
- Collapsible (tap header to minimize)
- Updates in real-time

---

### 5. Next Segment Preview
**Position:** Above bottom actions

```swift
┌────────────────────────────────────────────────┐
│  Up Next: ❄️ SkiErg 1000m                      │
│  Target: <4:30   •   Rest before: 90s          │
└────────────────────────────────────────────────┘
```

**Design:**
- Dark card with subtle border
- 15pt text
- Shows what's coming to help athlete prepare mentally
- Can tap to see full segment details

---

### 6. Action Buttons (Floating)
**Position:** Fixed at bottom, above safe area

```swift
┌────────────┐  ┌────────────┐  ┌────────────┐
│    ⏸      │  │     →      │  │     ✕      │
│   Pause    │  │    Next    │  │    End     │
└────────────┘  └────────────┘  └────────────┘
```

**Design:**
- 3 equal-width buttons
- Height: 56pt (tappable)
- Translucent dark background with blur
- Pause: Yellow accent
- Next: Green accent
- End: Red accent
- Icons + labels

**Interactions:**
- Pause → Shows pause overlay
- Next → Skip to next segment (confirmation)
- End → End workout (confirmation)

---

## Segment Transition Screen

When transitioning between segments, show full-screen transition:

```
┌─────────────────────────────────────────────────┐
│                                                  │
│              SEGMENT COMPLETE                    │
│                                                  │
│  ✓ Run 1 • 1000m                                │  ← Just finished
│    Time: 4:58  Target: 4:45-5:00  ✓             │
│    Avg Pace: 4:58/km                            │
│    Avg HR: 165 bpm                              │
│                                                  │
│  ─────────────────────────────────────────      │
│                                                  │
│  AI COACHING MESSAGE                            │  ← Contextual
│  "Strong run! Your pace was right on target.    │
│  SkiErg is next - focus on powerful pulls       │
│  and controlled breathing. You've got this."    │
│                                                  │
│  ─────────────────────────────────────────      │
│                                                  │
│  NEXT UP                                        │
│  ❄️ SkiErg 1000m                                │  ← What's next
│  Target: <4:30                                  │
│  Focus: Maintain stroke rate 35-40 SPM         │
│                                                  │
│                                                  │
│              Starting in 5...                   │  ← Countdown
│                                                  │
│              [Skip Rest]                        │
│                                                  │
└─────────────────────────────────────────────────┘
```

**Features:**
- Full-screen takeover
- Celebration of completed segment
- AI coaching contextual to what just happened
- Preview of next segment
- Auto-countdown (5 seconds default)
- Option to skip rest
- Haptic feedback at 3-2-1-START

---

## Pause Overlay

When paused, show overlay instead of new screen:

```
┌─────────────────────────────────────────────────┐
│  [Dimmed workout screen behind]                  │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │                                            │ │
│  │              PAUSED                        │ │
│  │                                            │ │
│  │  Elapsed: 12:45                           │ │
│  │  Current: Run 2 • 450m remaining          │ │
│  │                                            │ │
│  │  ┌────────────────────────────────────┐   │ │
│  │  │          Resume                     │   │ │  ← Primary
│  │  └────────────────────────────────────┘   │ │
│  │                                            │ │
│  │  ┌────────────────────────────────────┐   │ │
│  │  │       End Workout                  │   │ │  ← Destructive
│  │  └────────────────────────────────────┘   │ │
│  │                                            │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
└─────────────────────────────────────────────────┘
```

**Design:**
- Semi-transparent dark overlay
- Central card with blur background
- Large Resume button (green)
- End Workout below (red, secondary style)
- Tap outside card to resume

---

## Design System

### Colors
- **Background:** Pure black (#000000)
- **Surface:** Dark gray (#1C1C1E)
- **Primary:** Apple green (#30D158)
- **Warning:** Yellow (#FFD60A)
- **Danger:** Red (#FF453A)
- **HR Zones:**
  - Z1: #8E8E93 (gray)
  - Z2: #64D2FF (blue)
  - Z3: #30D158 (green)
  - Z4: #FF9F0A (orange)
  - Z5: #FF453A (red)

### Typography
- **Hero metrics:** 120pt SF Pro Rounded Medium, tabular
- **Large metrics:** 36pt SF Pro Rounded Medium, tabular
- **Headers:** 20pt SF Pro Semibold
- **Body:** 17pt SF Pro Regular
- **Labels:** 13pt SF Pro Semibold, uppercase, gray

### Spacing
- Screen padding: 20pt horizontal
- Card internal padding: 16pt
- Vertical spacing between sections: 20pt
- Grid gap: 12pt

### Animation
- Value updates: 0.2s ease-out
- Transitions: 0.3s spring (damping 0.8)
- Haptics: Impact feedback on actions, notification on milestones

---

## Interaction Patterns

### Gestures
- **Swipe up/down:** Scroll through workout view
- **Tap metric cards:** Expand for more details
- **Long-press action buttons:** Quick confirmation (e.g., long-press End to skip confirmation)
- **Tap outside overlays:** Dismiss

### Real-time Updates
- Metrics update every 0.5 seconds
- Smooth animated transitions for changing values
- No jarring jumps or flickers
- Progress bars animate fluidly

### Feedback
- **Haptic feedback:**
  - Light impact: Button taps
  - Medium impact: Segment transitions
  - Heavy impact: Workout start/end
  - Success notification: Segment complete
  - Warning notification: Off-pace alerts

---

## Advantages Over Current Design

### Current (Watch-style TabView):
- ❌ 4 separate pages requiring swipes
- ❌ Limited information visible at once
- ❌ Doesn't use available screen space
- ❌ Feels cramped on large screen
- ❌ Have to remember which page has which metric

### Proposed (iPhone-optimized):
- ✅ All key metrics visible simultaneously
- ✅ Larger, more readable text (120pt vs 72pt)
- ✅ Contextual information hierarchy
- ✅ Feels premium on large display
- ✅ Less interaction needed during workout
- ✅ Real-time graph visible without switching
- ✅ Natural scrolling interaction (familiar iOS pattern)

---

## Implementation Notes

### File Structure
```
/Sources/Features/Workout/iPhone/
├── WorkoutView.swift                 # Main container
├── Components/
│   ├── SegmentHeader.swift          # Fixed header
│   ├── PrimaryMetric.swift          # Large display
│   ├── LiveMetricsGrid.swift        # 2x2 metrics
│   ├── HeartRateGraph.swift         # Live HR chart
│   ├── NextSegmentPreview.swift     # What's next
│   └── ActionButtons.swift          # Bottom controls
├── Overlays/
│   ├── SegmentTransition.swift      # Between segments
│   ├── PauseOverlay.swift           # Pause screen
│   └── WorkoutComplete.swift        # End celebration
└── ViewModels/
    └── WorkoutViewModel.swift       # Shared state
```

### Technology
- **SwiftUI** for all UI
- **Swift Charts** for heart rate graph
- **Core Haptics** for feedback
- **HealthKit** for live HR data
- **Combine** for reactive updates

### Performance
- Optimize for 60fps during workout
- Efficient view updates (only changed components)
- Throttle metric updates to 0.5s intervals
- Background thread for calculations

---

## Migration Strategy

### Phase 1: Build New Components
- Create new iPhone workout views
- Keep existing Watch-style view
- Test new design thoroughly

### Phase 2: Feature Flag
- Add setting to switch between layouts
- Let users choose during beta
- Gather feedback

### Phase 3: Default to New Design
- Make iPhone-optimized layout default
- Keep old layout as "Compact Mode" option
- Full rollout after validation

---

## Future Enhancements

### Phase 2 Features:
- **Audio coaching** - Spoken cues at key moments
- **Live comparison** - Compare to previous workout in real-time
- **Social feed** - See friends' times during workout
- **Workout photo** - Auto-capture photo at finish

### Advanced Metrics:
- **Power curve** (for erg stations)
- **Cadence graph** (for running)
- **Form analysis** (from Watch accelerometer)
- **Fatigue indicator** (pace degradation visualization)

---

## Mockup Summary

This redesign:
1. **Respects Apple Fitness+ aesthetic** - Clean, premium, focused
2. **Optimizes for iPhone screen** - Uses available space intelligently
3. **Shows more information** - All key metrics visible at once
4. **Maintains focus** - Clear visual hierarchy, hero metric dominates
5. **Reduces interaction** - Less swiping, scrolling is natural
6. **Feels professional** - Premium typography, smooth animations
7. **Provides context** - Next segment, AI coaching, progress

**Result:** A workout experience that feels native to iPhone, premium like Apple Fitness+, and optimized for HYROX's unique requirements.

---

*Document Version: 1.0*
*Created: December 2025*
*Status: Design Proposal - Ready for Review & Implementation*
