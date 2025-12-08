#!/usr/bin/env ruby

# Final Analytics Fix - Use same approach that worked for original 108 files
# This removes all build file entries and re-adds them correctly

require 'xcodeproj'

PROJECT_PATH = 'FLEXR.xcodeproj'
TARGET_NAME = 'FLEXR'

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }

unless target
  puts "❌ Target '#{TARGET_NAME}' not found"
  exit 1
end

# Files to fix
files_to_fix = [
  'FLEXR/Sources/Core/Database/WorkoutEntity+Extensions.swift',
  'FLEXR/Sources/Core/Services/AnalyticsService.swift',
  'FLEXR/Sources/Features/Analytics/Views/AnalyticsContainerView.swift',
  'FLEXR/Sources/Features/Analytics/Views/AnalyticsDashboardView.swift',
  'FLEXR/Sources/Features/Analytics/Views/HeartRateAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/HyroxRunningAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/RecoveryAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/RunningWorkoutsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/StationAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Workout/WorkoutHistoryView.swift'
]

puts "🔧 Final analytics fix using working approach..."

# Step 1: Remove ALL file references and build file entries
puts "\n📝 Step 1: Complete cleanup..."
files_to_fix.each do |file_path|
  filename = File.basename(file_path)

  # Remove from build phase
  target.source_build_phase.files.each do |build_file|
    if build_file.file_ref&.path&.include?(filename) || build_file.file_ref&.display_name == filename
      puts "   Removing build file: #{build_file.file_ref.path}"
      target.source_build_phase.files.delete(build_file)
    end
  end

  # Remove file references
  project.files.each do |file_ref|
    if file_ref.path&.include?(filename) || file_ref.display_name == filename
      puts "   Removing file ref: #{file_ref.path}"
      file_ref.remove_from_project
    end
  end
end

# Step 2: Re-add with correct paths using relative references
puts "\n📝 Step 2: Re-adding files..."
files_to_fix.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)
  unless File.exist?(full_path)
    puts "   ⚠️  Not found: #{file_path}"
    next
  end

  # Find the group (navigate hierarchy)
  parts = file_path.split('/')
  group = project.main_group

  parts[0..-2].each do |part_name|
    child = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == part_name }
    if child
      group = child
    else
      # Create group if it doesn't exist
      group = group.new_group(part_name, part_name)
    end
  end

  # Create file reference using new_reference (not new_file)
  filename = parts.last
  file_ref = group.new_reference(filename)
  file_ref.set_source_tree('<group>')
  file_ref.set_last_known_file_type('sourcecode.swift')

  # Add to compile sources
  build_file = target.source_build_phase.add_file_reference(file_ref)

  puts "   ✓ Added: #{file_path}"
end

# Save
project.save

puts "\n✅ Analytics files fixed!"
