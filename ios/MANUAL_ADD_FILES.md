# Manual Instructions to Add Onboarding Files to Xcode

The automated script had issues with file path management. Here's the quick manual way (30 seconds):

## Steps:

1. **Open the project in Xcode:**
   ```bash
   open FLEXR.xcodeproj
   ```

2. **In Xcode Project Navigator (left sidebar):**
   - Navigate to `FLEXR > Sources > Core > Models`
   - Right-click on `Models` folder → Add Files to "FLEXR"...
   - Select: `FLEXR/Sources/Core/Models/OnboardingData.swift`
   - ✅ Make sure "Add to targets: FLEXR" is checked
   - Click "Add"

3. **Still in Project Navigator:**
   - Navigate to `FLEXR > Sources > Features > Onboarding`
   - Right-click on `Onboarding` folder → Add Files to "FLEXR"...
   - Select ALL 7 files:
     - OnboardingCoordinator.swift
     - OnboardingStep1_BasicProfile.swift
     - OnboardingStep2_GoalRaceDetails.swift
     - OnboardingStep3_TrainingAvailability.swift
     - OnboardingStep4_EquipmentAccess.swift
     - OnboardingStep5_PerformanceNumbers.swift
     - OnboardingCompletionView.swift
   - ✅ Make sure "Add to targets: FLEXR" is checked
   - Click "Add"

4. **Build the project:**
   - Press `⌘+B` or Product → Build
   - Should build successfully!

## Files to Add:

### Models folder:
- `OnboardingData.swift` ✓ Created

### Onboarding folder:
- `OnboardingCoordinator.swift` ✓ Created
- `OnboardingStep1_BasicProfile.swift` ✓ Created
- `OnboardingStep2_GoalRaceDetails.swift` ✓ Created
- `OnboardingStep3_TrainingAvailability.swift` ✓ Created
- `OnboardingStep4_EquipmentAccess.swift` ✓ Created
- `OnboardingStep5_PerformanceNumbers.swift` ✓ Created
- `OnboardingCompletionView.swift` ✓ Created

All files are already created in the correct locations - just need to be added to the Xcode project!

## Alternative: Use Add Files Dialog

Or even simpler:
1. Open Xcode
2. File → Add Files to "FLEXR"...
3. Navigate to `/Users/alexsolecarretero/Public/projects/FLEXR/ios/FLEXR/Sources/Core/Models`
4. Select `OnboardingData.swift`
5. ✅ Check "Add to targets: FLEXR"
6. Click "Add"
7. Repeat for the 7 onboarding files in `FLEXR/Sources/Features/Onboarding/`

That's it! The project should build successfully after this.
