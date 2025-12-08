#!/usr/bin/env ruby
# Script to add Mission Control files to Xcode project
# Requires: gem install xcodeproj

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Workout group
workout_group = project.main_group.find_subpath('FLEXR/Sources/Features/Workout', true)

if workout_group.nil?
  puts "❌ Could not find Workout group in project"
  exit 1
end

# Create MissionControl group
mission_control_group = workout_group.new_group('MissionControl', 'FLEXR/Sources/Features/Workout/MissionControl')

# Add ViewModels group
viewmodels_group = mission_control_group.new_group('ViewModels', 'FLEXR/Sources/Features/Workout/MissionControl/ViewModels')

# Add Components group
components_group = mission_control_group.new_group('Components', 'FLEXR/Sources/Features/Workout/MissionControl/Components')

# Add main view
main_view_file = mission_control_group.new_file('FLEXR/Sources/Features/Workout/MissionControl/WorkoutMissionControlView.swift')

# Add ViewModel
viewmodel_file = viewmodels_group.new_file('FLEXR/Sources/Features/Workout/MissionControl/ViewModels/MissionControlViewModel.swift')

# Add component files
component_files = [
  'ProjectedFinishBanner.swift',
  'CompletedSegmentCard.swift',
  'LiveSegmentCard.swift',
  'UpcomingSegmentCard.swift',
  'PaceDegradationGraph.swift',
  'HRZonesCard.swift',
  'AIInsightsCard.swift',
  'PerformanceStatsCard.swift'
]

component_files.each do |filename|
  components_group.new_file("FLEXR/Sources/Features/Workout/MissionControl/Components/#{filename}")
end

# Add files to build target
target = project.targets.first

# Add to compile sources
[main_view_file, viewmodel_file].each do |file_ref|
  target.add_file_references([file_ref])
end

components_group.files.each do |file_ref|
  target.add_file_references([file_ref])
end

# Save project
project.save

puts "✅ Successfully added Mission Control files to Xcode project!"
puts "📦 Added 10 files:"
puts "   - MissionControlViewModel.swift"
puts "   - WorkoutMissionControlView.swift"
puts "   - 8 component files"
puts ""
puts "🚀 You can now build the project!"
