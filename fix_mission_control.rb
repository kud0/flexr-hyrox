#!/usr/bin/env ruby
# Script to fix Mission Control file paths in Xcode project
# Requires: gem install xcodeproj

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔍 Removing old Mission Control references..."

# Find and remove old MissionControl group
workout_group = project.main_group.find_subpath('FLEXR/Sources/Features/Workout', false)
if workout_group
  mission_control_group = workout_group.children.find { |g| g.display_name == 'MissionControl' }
  if mission_control_group
    mission_control_group.remove_from_project
    puts "   ✓ Removed old MissionControl group"
  end
end

puts "\n📦 Adding Mission Control files with correct paths..."

# Find the Workout group (should already exist)
workout_group = project.main_group.find_subpath('FLEXR/Sources/Features/Workout', false)

if workout_group.nil?
  puts "❌ Could not find Workout group in project"
  exit 1
end

# Create MissionControl group (no path parameter - it inherits from parent)
mission_control_group = workout_group.new_group('MissionControl')
mission_control_group.path = 'MissionControl'

# Add ViewModels group
viewmodels_group = mission_control_group.new_group('ViewModels')
viewmodels_group.path = 'ViewModels'

# Add Components group
components_group = mission_control_group.new_group('Components')
components_group.path = 'Components'

# Add main view (relative path)
main_view_file = mission_control_group.new_file('WorkoutMissionControlView.swift')

# Add ViewModel (relative path)
viewmodel_file = viewmodels_group.new_file('MissionControlViewModel.swift')

# Add component files (relative paths)
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
  components_group.new_file(filename)
end

# Add files to build target (FLEXR iOS app, not Watch)
target = project.targets.find { |t| t.name == 'FLEXR' }

if target.nil?
  puts "❌ Could not find FLEXR target"
  exit 1
end

# Add to compile sources
[main_view_file, viewmodel_file].each do |file_ref|
  target.add_file_references([file_ref])
end

components_group.files.each do |file_ref|
  target.add_file_references([file_ref])
end

# Save project
project.save

puts "\n✅ Successfully fixed Mission Control file paths!"
puts "📦 Added 10 files with correct paths:"
puts "   - WorkoutMissionControlView.swift"
puts "   - MissionControlViewModel.swift"
puts "   - 8 component files"
puts ""
puts "🚀 You can now build the project!"
