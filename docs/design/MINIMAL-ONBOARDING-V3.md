# FLEXR Onboarding - Minimal Core + Optional Refinement
## Get Them Training in 5 Minutes, Refine When Ready

**Philosophy**: Perfect is the enemy of good. Get them started fast, improve over time.

---

## PART 1: CORE ONBOARDING (5-7 minutes, ~12 questions)

**Goal**: Minimum info needed to generate first training week

### SECTION 1: Basic Profile (1 min)
```
1. Age, Weight, Height, Gender (standard signup)

2. Training Background:
   ○ New to fitness
   ○ Gym regular
   ○ Runner
   ○ CrossFit/Functional
   ○ HYROX veteran

   → AI uses this to estimate fitness level
```

### SECTION 2: Your Goal (2 min)
```
3. What's your main goal?
   ○ Complete my first HYROX
   ○ Improve my HYROX time (PR)
   ○ Podium / Competitive
   ○ Train HYROX style (no race planned)

4. If racing - When?
   📅 [Date Picker] OR "No race scheduled"

   → AI calculates weeks to race, determines phases

5. Target time (if racing)?
   ○ Just finish
   ○ Sub 2:00
   ○ Sub 1:30
   ○ Sub 1:15
   ○ Sub 1:00
   ○ Podium

   → AI sets intensity/volume targets
```

### SECTION 3: Training Availability (2 min)
```
6. How many days per week can you train?
   ○ 3 days
   ○ 4 days
   ○ 5 days
   ○ 6 days
   ○ 7 days (elite)

7. Sessions per day?
   ○ 1 session (most people)
   ○ 2 sessions (serious athletes)

8. Preferred training time?
   ○ Morning
   ○ Afternoon
   ○ Evening
   ○ Flexible

   → AI schedules workouts optimally
```

### SECTION 4: Equipment Access (2 min)
```
9. Where do you train?

   ☐ HYROX-equipped gym (has all stations)
   ☐ CrossFit/Functional gym (most equipment)
   ☐ Commercial gym (standard gym)
   ☐ Home gym (select what you have →)
   ☐ Minimal/Outdoor (bodyweight + running)

   → Smart defaults apply, user can refine later

10. If HOME GYM, what do you have? (quick checklist)
    ☐ Rower  ☐ SkiErg  ☐ Barbell  ☐ Dumbbells
    ☐ Kettlebells  ☐ Pull-up bar  ☐ Just running

    → AI builds plan around available equipment
```

### SECTION 5: Apple Watch (1 min)
```
11. Connect Apple Watch?
    [Connect Now] [Skip for now]

    → Unlocks heart rate zones, readiness tracking
```

### SECTION 6: Start Training (1 min)
```
12. Quick calibration (optional - can skip):
    "If you know these, it helps. If not, we'll learn together!"

    Running 1km pace: [__:__] OR "I don't know"
    5km time: [__:__] OR "I don't know"

    → If skipped, AI starts conservative and learns from first week

[Generate My First Week] ← BIG BUTTON
```

---

## AI GENERATES FIRST WEEK

**Using Minimal Info:**
```python
# What AI knows:
athlete = {
    'background': 'gym_regular',
    'goal': 'first_hyrox',
    'race_date': '2025-06-15',  # 24 weeks out
    'target': 'sub_2_hours',
    'days_per_week': 4,
    'sessions_per_day': 1,
    'time_preference': 'morning',
    'equipment': 'crossfit_gym',  # has most stuff
    'apple_watch': True,
    'running_1km': None,  # Don't know yet
    'running_5km': None,  # Don't know yet
}

# What AI assumes:
- Fitness level: 'intermediate' (from "gym regular")
- Week 1: Conservative start, learn from feedback
- Weights: Start light based on intermediate estimates
- Running pace: Use first workout to calibrate
- Weaknesses: Unknown, discover in Week 1-2
- Progression: Standard (based on 24 weeks to race)

# First Week Strategy:
- Week 1: "Assessment Week"
  - Light weights (60-70% of estimated)
  - Mixed workouts to discover strengths/weaknesses
  - Heavy feedback collection
  - Learn running paces, station capacity

- Week 2+: Adjust based on Week 1 feedback
  - AI learned actual capacity
  - Increase weights where user said "too easy"
  - Focus on identified weaknesses
  - Dial in pacing
```

---

## AFTER FIRST WEEK: Prompt for Refinement

**Day 8 Notification:**
```
┌─────────────────────────────────────────┐
│  Great first week! 🎉                   │
│                                         │
│  I learned a lot about you from your    │
│  workouts and feedback.                 │
│                                         │
│  Want an even BETTER plan?              │
│                                         │
│  [Refine My Plan] (5 min)               │
│                                         │
│  Or keep going - I'll keep learning!    │
│  [Continue Current Plan]                │
│                                         │
└─────────────────────────────────────────┘
```

---

## PART 2: OPTIONAL REFINEMENT (Later, when ready)

**Triggered by:**
- User clicks "Refine My Plan" after Week 1
- User goes to Settings → "Improve My Plan"
- AI suggests after 2-4 weeks: "Ready to level up your plan?"

**Takes 5-10 minutes, HUGE impact on plan quality**

### REFINEMENT SECTION 1: Your Numbers (2 min)
```
"I've learned from your workouts, but let's get precise:"

RUNNING (if you know):
- Fresh 1km pace: [__:__] (I estimated: 5:15 from your Week 1 data)
- 5km time: [__:__] (I estimated: 27:30)
- Comfortable Zone 2: [__:__] (I estimated: 6:00)

STRENGTH (optional):
- Back Squat (1RM or 5-rep): [___kg]
  💡 Helps me prescribe sled weights
- Deadlift (1RM or 5-rep): [___kg]
  💡 Helps me prescribe farmers carry

HYROX STATIONS (if you've tried):
- SkiErg 1000m: [__:__]
- Sled Push 50m: [__sec] at [__kg]
- Rowing 1000m: [__:__]
- Wall Balls unbroken: [__reps]
- Burpees in 1min: [__reps]

[Update My Numbers]
```

### REFINEMENT SECTION 2: Weaknesses & Focus (2 min)
```
"What are you struggling with most?"

Station Weaknesses (pick up to 3):
☐ SkiErg - "I gas out fast"
☐ Sled Push - "Legs die"
☐ Sled Pull - "Grip fails"
☐ Burpee Broad Jumps - "Slow and painful"
☐ Rowing - "Can't hold pace"
☐ Farmers Carry - "Grip/core gives out"
☐ Sandbag Lunges - "Brutal on quads"
☐ Wall Balls - "Shoulders/legs burn"
☐ Running after stations - "Pace falls apart"
☐ None - I'm balanced

→ AI adds +30% volume to weak areas

Injuries or pain? (we'll modify exercises)
☐ Knee issues
☐ Lower back
☐ Shoulder
☐ Ankle
☐ Hip flexor
☐ None
☐ Other: [___]

[Save Weaknesses]
```

### REFINEMENT SECTION 3: Training Style (2 min)
```
"How do you train best?"

Training Split Preference:
○ MIXED SESSIONS (3 HYROX + 3 runs per week)
  Best for balanced development

○ COMPROMISED FOCUS (stations + running every session)
  Best for HYROX race specificity

○ DEDICATED BLOCKS (running days separate from strength days)
  Best for quality work in each domain

○ LET AI DECIDE
  AI mixes it up based on readiness

---

What drives you?
○ Competition - I want to beat others
○ Self-improvement - I compete with myself
○ Health & fitness - I want to feel great
○ The challenge - I like hard things

→ AI adjusts coaching tone and workout style

[Save Preferences]
```

### REFINEMENT SECTION 4: Strength Ranking (2 min)
```
"Drag to order from STRONGEST → WEAKEST:"

[Draggable list - takes 30 seconds!]
1. _______________ (your strongest)
2. _______________
3. _______________
4. _______________
5. _______________
6. _______________
7. _______________ (your weakest)

Options to drag:
- Leg strength (squats, lunges)
- Core stability
- Upper push (push-ups, pressing)
- Upper pull (pull-ups, rows)
- Posterior chain (deadlifts, hamstrings)
- Grip endurance
- Explosive power (jumps, sprints)

→ AI starts strong areas higher, builds weak areas

[Save Ranking]
```

### REFINEMENT COMPLETE
```
┌─────────────────────────────────────────┐
│  🧠 Got it! Rebuilding your plan...     │
│                                         │
│  Changes based on your refinement:      │
│                                         │
│  ✓ Running paces adjusted to your PRs  │
│  ✓ Sled weights increased to 85kg      │
│    (based on your squat)                │
│  ✓ Extra focus on SkiErg + Sled Push   │
│    (your weak stations)                 │
│  ✓ Grip work added 3x/week             │
│    (your weakest strength area)         │
│  ✓ Training split: Compromised focus   │
│    (your preference)                    │
│                                         │
│  [See My New Plan]                      │
│                                         │
└─────────────────────────────────────────┘
```

---

## PART 3: CONTINUOUS LEARNING (No Extra Questions!)

**AI Gets Smarter Every Workout:**

### After Workout Feedback (30 seconds)
```
Quick feedback:
1. Difficulty (RPE): 1━━━━━●━━━━10

2. Weights used:
   Sled Push: [220]kg ← You used 210kg last time
   Farmers: [40]kg each

3. Any issues?
   ☐ Too easy  ☐ Too hard  ☐ Felt great ✓

[Submit] (takes 10 seconds)
```

### AI Learns:
- Week 1: "RPE 4/10, too easy" → Increase 20%
- Week 2: "RPE 7/10, perfect" → Maintain + small progression
- Week 3: "RPE 9/10, struggled" → Hold or reduce slightly
- Week 4: "Running pace fading after stations" → Add compromised running drills

### After 4 Weeks: AI Suggests Refinement
```
┌─────────────────────────────────────────┐
│  📊 I've learned a lot in 4 weeks!      │
│                                         │
│  I noticed:                             │
│  • Your running improved 15sec/km       │
│  • SkiErg is still your weakness        │
│  • You crush leg strength work          │
│  • Grip endurance needs work            │
│                                         │
│  Want me to rebuild your plan with      │
│  these insights?                        │
│                                         │
│  [Yes, Optimize My Plan]                │
│  [No, Keep Current Plan]                │
│                                         │
└─────────────────────────────────────────┘
```

---

## PART 4: SETTINGS - "Improve My Plan" (Always Available)

**User can refine anytime:**

```
Settings > Training Preferences > Improve My Plan

┌─────────────────────────────────────────┐
│  IMPROVE MY PLAN                        │
│                                         │
│  Make your training even more           │
│  personalized. Each section is optional.│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  📊 MY PERFORMANCE NUMBERS          ││
│  │  Add PRs for better prescriptions   ││
│  │  (2 min)                            ││
│  │                           [Update]  ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  🎯 WEAKNESSES & FOCUS              ││
│  │  Target your limiters               ││
│  │  (2 min)                            ││
│  │                           [Update]  ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  ⚙️ TRAINING STYLE                  ││
│  │  How you like to train              ││
│  │  (2 min)                            ││
│  │                           [Update]  ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  💪 STRENGTH RANKING                ││
│  │  Order your strengths               ││
│  │  (1 min)                            ││
│  │                           [Update]  ││
│  └─────────────────────────────────────┘│
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  🏋️ EQUIPMENT                       ││
│  │  Update what you have access to     ││
│  │  (1 min)                            ││
│  │                           [Update]  ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘

💡 Each update improves your plan immediately
```

---

## PART 5: THE ONBOARDING COMPARISON

### ❌ OLD APPROACH (Overwhelming)
```
All 25+ questions upfront
↓
15-20 minute onboarding
↓
User fatigue, drop-off
↓
Perfect plan Day 1
↓
But 40% never finish onboarding
```

### ✅ NEW APPROACH (Progressive)
```
12 essential questions
↓
5-7 minute onboarding
↓
Good plan Day 1
↓
Week 1 feedback teaches AI
↓
Prompt for refinement (optional)
↓
Great plan Week 2+
↓
Continuous improvement
↓
User can refine anytime
```

---

## PART 6: USER PSYCHOLOGY

### Why This Works:

**1. Respect User Time**
- 5 minutes to start > 20 minutes never finished
- "Get me training NOW" > "Tell me your life story"

**2. Progressive Commitment**
- Week 1: Low commitment, try it out
- Week 2: Hooked, willing to spend 5 min refining
- Week 4: Invested, want optimization

**3. Show Value First**
- Don't ask for data before proving worth
- First week proves AI works
- THEN ask for more to make it better

**4. Optional = No Pressure**
- "Want a better plan?" not "Complete your profile!"
- User feels in control
- Can refine in pieces (just numbers, just weaknesses, etc.)

**5. Clear Benefits**
- Each refinement shows: "This unlocks: [better weights/weakness focus/etc]"
- User sees direct ROI on their time

---

## PART 7: IMPLEMENTATION PRIORITY

### Phase 1: Core Onboarding (Week 1-2)
- 12-question minimal flow
- Smart equipment defaults
- Apple Watch connection
- Generate first week

### Phase 2: First Week "Assessment" (Week 2-3)
- Week 1 workouts designed to learn
- Heavy feedback collection
- AI learns capacity, paces, weaknesses
- Prepare refinement suggestions

### Phase 3: Refinement Flow (Week 3-4)
- "Refine My Plan" prompt after Week 1
- 4 optional sections (numbers, weaknesses, style, ranking)
- Settings → "Improve My Plan" always available
- Rebuild plan with new data

### Phase 4: Continuous Learning (Week 4-5)
- Post-workout feedback (RPE + weights)
- AI adjusts weekly based on data
- Periodic "I've learned, want me to rebuild?" prompts
- No-effort improvement over time

---

## PART 8: THE MAGIC FORMULA

```
MINIMAL ONBOARDING
    +
SMART DEFAULTS
    +
FIRST WEEK LEARNING
    +
OPTIONAL REFINEMENT
    +
CONTINUOUS FEEDBACK
    =
WORLD-CLASS PERSONALIZATION
(Without overwhelming users)
```

---

## EXAMPLE: MARIA'S JOURNEY

### Day 1: Core Onboarding (5 min)
```
Maria answers:
- CrossFit background
- First HYROX, 16 weeks out
- Target: Sub 1:45
- 5 days/week, 1 session/day
- Morning preference
- CrossFit gym (has most equipment)
- Doesn't know running PRs

[Generate My First Week]

AI creates Week 1 "Assessment Week":
- Light weights (conservative start)
- Mixed workouts to discover strengths/weaknesses
- First run will calibrate her paces
```

### Day 1-7: Week 1 Training
```
Monday: Station introduction (learns she crushes leg work)
Tuesday: Running intervals (AI measures: 4:50/km is her 1km pace)
Wednesday: Strength (confirms CrossFit strength carries over)
Thursday: SkiErg focus (she struggles here - weakness found!)
Friday: First compromised run (pace fades 20sec/km - normal for newbie)

After each workout: Quick feedback (30 sec)
- Sled push: "Too light, felt like warmup"
- SkiErg: "This is hard, my limiting factor"
```

### Day 8: Refinement Prompt
```
"Great first week! 🎉

I learned:
• You're strong (crush sled, squats, carries)
• Running is good (4:50/km pace)
• SkiErg is your weakness
• Weights were too light

Want a better plan? (5 min)

[Yes, Refine It]  [Later]
```

Maria clicks "Yes" (she's hooked!)

### Day 8: Maria Refines (5 min)
```
Section 1: Numbers
- Running 1km: 4:50 ✓ (AI already learned this)
- 5km time: 26:30 (new info!)
- Squat: 85kg (new info! → sled weights up to 50kg)

Section 2: Weaknesses
- SkiErg ✓
- Sled Pull ✓
- Grip endurance

Section 3: Style
- Prefers: Compromised focus (running after stations)
- Drives her: Self-improvement

Section 4: Strength ranking
[Drags in 30 seconds]
1. Leg strength (strongest)
2. Core
3. Upper push
4. Posterior
5. Upper pull
6. Power
7. Grip (weakest) ← matches SkiErg weakness!
```

### Day 8: New Plan Generated
```
"Based on refinement:

Changes to your plan:
✓ Sled weights: 35kg → 50kg (from squat PR)
✓ SkiErg volume: 2x/week → 4x/week (+100%)
✓ Grip prehab: Added 3x/week
✓ Compromised running every session (your pref)
✓ Paces adjusted to your 5km time

Week 2 starts tomorrow - ready to crush it!"
```

### Weeks 2-16: Continuous Improvement
- Each workout refines understanding
- Weights progress based on RPE
- No more questions needed
- Plan evolves organically

**Maria never felt overwhelmed. She felt GUIDED.**

---

**THIS is the way.** ✨

*Document Version: 3.0 - Minimal Core*
*Created: December 2025*
*Status: Perfect Balance - Ready to Build*
