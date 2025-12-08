#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find FLEXR target
flexr_target = project.targets.find { |t| t.name == 'FLEXR' }

unless flexr_target
  puts "❌ FLEXR target not found"
  exit 1
end

puts "➕ Adding missing files with correct paths..."

# List of files to add (relative to FLEXR/ directory)
files_to_add = [
  'Sources/Core/Services/WatchConnectivityService.swift',
  'Sources/Core/Services/AppleSignInService.swift',
  'Sources/Core/Services/PlanService.swift',
  'Sources/Core/Database/CoreDataManager.swift',
  'Sources/Features/Onboarding/OnboardingView.swift',
  'Sources/Core/Models/RouteData.swift',
  'Sources/Features/Onboarding/PlanGeneratingView.swift',
  'Sources/Features/Onboarding/OnboardingStep8_WatchPairing.swift',
  'Sources/Features/Onboarding/OnboardingCoordinator.swift',
  'Sources/Features/Onboarding/TrainingArchitectureView.swift',
  'Sources/Features/Onboarding/OnboardingStep3_TrainingAvailability.swift',
  'Sources/Features/Onboarding/GoalSelectionView.swift',
  'Sources/Features/Onboarding/ExperienceLevelView.swift',
  'Sources/Features/Onboarding/OnboardingStep4_EquipmentAccess.swift',
  'Sources/Features/Onboarding/HealthKitPermissionView.swift',
  'Sources/Features/Onboarding/OnboardingCompletionView.swift',
  'Sources/Features/Onboarding/OnboardingStep6_WorkoutDuration.swift',
  'Sources/Features/Onboarding/OnboardingStep9_HealthKitPermission.swift',
  'Sources/Features/Onboarding/WelcomeView.swift',
  'Sources/Features/Onboarding/RaceDateView.swift',
  'Sources/Features/Onboarding/OnboardingStep7_WorkoutTypePreferences.swift',
  'Sources/Features/Onboarding/EquipmentView.swift',
  'Sources/Features/Onboarding/OnboardingCompleteView.swift',
  'Sources/Features/Onboarding/OnboardingStep5_PerformanceNumbers.swift',
  'Sources/Features/Onboarding/OnboardingStep2_GoalRaceDetails.swift',
  'Sources/Features/Onboarding/OnboardingStep1_BasicProfile.swift',
  'Sources/Features/Onboarding/OnboardingViewModel.swift',
  'Sources/Features/Onboarding/WatchPairingView.swift',
  'Sources/Core/Models/RunningSession.swift',
  'Sources/Core/Models/TrainingArchitecture.swift',
  'Sources/Core/Models/PlannedWorkoutSegment.swift',
  'Sources/Core/Models/WorkoutAnalytics.swift',
  'Sources/Core/Models/Relationship.swift',
  'Sources/Core/Models/Gym.swift',
  'Sources/Core/Models/WorkoutSummary.swift',
  'Sources/Core/Models/OnboardingData.swift',
  'Sources/Core/Models/MockSocialData.swift',
  'Sources/Core/Models/SocialActivity.swift',
  'Sources/Core/Services/HealthKitRunningImport.swift',
  'Sources/Core/Services/WorkoutAnalyticsService.swift',
  'Sources/Core/Services/WorkoutIntegrationService.swift',
  'Sources/Core/Services/RunningService.swift',
  'Sources/Core/Services/UserStatsService.swift',
  'Sources/Core/Services/RelationshipService.swift',
  'Sources/Core/Services/SocialService.swift',
  'Sources/Core/Services/AnalyticsService.swift',
  'Sources/Core/Services/VideoRecordingService.swift',
  'Sources/Core/Services/GymService.swift',
  'Sources/Core/Services/SupabaseService.swift',
  'Sources/Core/Services/LocationTrackingService.swift',
  'Sources/Features/Video/TerminalOverlay.swift',
  'Sources/Features/Video/MinimalOverlay.swift',
  'Sources/Features/Video/VideoRecordingView.swift',
  'Sources/Features/Video/NeonEdgesOverlay.swift',
  'Sources/Features/Video/CustomizableOverlay.swift',
  'Sources/Features/Video/CleanWorkoutOverlay.swift',
  'Sources/Features/Training/TrainingCycleView.swift',
  'Sources/Features/Training/WeeklyPlanView.swift',
  'Sources/Features/Workout/WorkoutDetailView.swift',
  'Sources/Features/Dashboard/DashboardView.swift',
  'Sources/Features/Social/Gym/GymLeaderboardsView.swift',
  'Sources/Features/Social/Gym/GymSearchView.swift',
  'Sources/Features/Social/Gym/GymDetailView.swift',
  'Sources/Features/Analytics/Social/GymActivityFeedView.swift',
  'Sources/Features/Social/Gym/GymMembersView.swift',
  'Sources/Features/Social/Gym/GymCreationView.swift',
  'Sources/Features/Social/Gym/GymAdminView.swift',
  'Sources/Features/Social/Friends/FriendsListView.swift',
  'Sources/Features/Social/Friends/UserProfileDetailView.swift',
  'Sources/Features/Profile/ProfileView.swift',
  'Sources/Features/Profile/TrainingPreferencesView.swift',
  'Sources/Features/Workout/WorkoutExecutionView.swift',
  'Sources/Features/Workout/WorkoutExecutionViewModel.swift',
  'Sources/Features/Workout/Components/CompletedRouteMapView.swift',
  'Sources/Features/Workout/TripodModeView.swift',
  'Sources/Features/Workout/MissionControl/ViewModels/MissionControlViewModel.swift',
  'Sources/Features/Workout/MissionControl/Components/ProjectedFinishBanner.swift',
  'Sources/Features/Workout/MissionControl/Components/CompletedSegmentCard.swift',
  'Sources/Features/Workout/MissionControl/Components/LiveSegmentCard.swift',
  'Sources/Features/Workout/MissionControl/Components/PaceDegradationGraph.swift',
  'Sources/Features/Workout/MissionControl/Components/AIInsightsCard.swift',
  'Sources/Features/Workout/MissionControl/Components/HRZonesCard.swift',
  'Sources/Features/Workout/MissionControl/Components/PerformanceStatsCard.swift',
  'Sources/Features/Workout/MissionControl/Components/UpcomingSegmentCard.swift',
  'Sources/Features/Workout/MissionControl/WorkoutMissionControlView.swift',
  'Sources/Features/Workout/Active/HeartRatePageView.swift',
  'Sources/Features/Workout/Active/ControlsPageView.swift',
  'Sources/Features/Workout/Active/ActiveWorkoutHeader.swift',
  'Sources/Features/Workout/Active/SegmentInfoPageView.swift',
  'Sources/Features/Workout/Active/SegmentTransitionSheet.swift',
  'Sources/Features/Workout/Active/WorkoutActiveView.swift',
  'Sources/Features/Workout/Active/MetricsPageView.swift',
  'Sources/Features/Workout/WorkoutCompletionView.swift',
  'Sources/Features/Analytics/Running/GymRunningLeaderboardView.swift',
  'Sources/Features/Analytics/Running/RunningSessionDetailView.swift',
  'Sources/Features/Analytics/Running/RunningAnalyticsView.swift',
  'Sources/Features/Analytics/ViewModels/AnalyticsData.swift',
  'Sources/Features/Analytics/Models/AnalyticsTypes.swift',
  'Sources/Features/Analytics/Social/WorkoutSharingSheet.swift',
  'Sources/Features/Analytics/Components/MetricCard.swift',
  'Sources/Features/Analytics/Workout/WorkoutHistoryView.swift',
  'Sources/Features/Analytics/Views/AnalyticsDashboardView.swift',
  'Sources/Features/Analytics/Views/RunningWorkoutsView.swift',
  'Sources/Features/Analytics/Views/StationAnalyticsView.swift',
  'Sources/Features/Analytics/Views/HeartRateAnalyticsView.swift',
  'Sources/Features/Analytics/Views/HyroxRunningAnalyticsView.swift',
  'Sources/Features/Analytics/Views/AnalyticsContainerView.swift',
  'Sources/Features/Analytics/Views/RecoveryAnalyticsView.swift',
  'Sources/UI/Components/UnifiedComponents.swift',
  'Sources/Features/Training/PlannedWorkoutDetailView.swift'
]

# Get the FLEXR group
flexr_group = project.main_group.find_subpath('FLEXR', true)

# Get sources phase
sources_phase = flexr_target.source_build_phase

added_count = 0
already_exists = 0
not_found = 0

files_to_add.each do |relative_path|
  # Check if file already exists in project
  existing = sources_phase.files.find do |build_file|
    build_file.file_ref && build_file.file_ref.real_path.to_s.end_with?(relative_path)
  end

  if existing
    already_exists += 1
    next
  end

  # Find or create file reference
  file_path = File.join('FLEXR', relative_path)

  # Check if file exists on disk
  unless File.exist?(file_path)
    puts "  ⚠️  File not found: #{file_path}"
    not_found += 1
    next
  end

  # Create file reference
  file_ref = flexr_group.new_reference(file_path)

  # Add to sources build phase
  sources_phase.add_file_reference(file_ref)

  puts "  ✅ Added: #{relative_path}"
  added_count += 1
end

puts "\n" + "=" * 80
puts "✅ Added #{added_count} files"
puts "⏭  Skipped #{already_exists} files (already in project)"
puts "⚠️  #{not_found} files not found on disk" if not_found > 0

# Save project
project.save

puts "💾 Project saved successfully"
puts "\n🎉 Missing files restored!"
