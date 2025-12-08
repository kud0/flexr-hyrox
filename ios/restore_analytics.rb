#!/usr/bin/env ruby

# Restore Analytics Files to Xcode Project
# This script re-adds all analytics-related files back to the FLEXR target

require 'xcodeproj'

PROJECT_PATH = 'FLEXR.xcodeproj'
TARGET_NAME = 'FLEXR'

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }

unless target
  puts "❌ Target '#{TARGET_NAME}' not found"
  exit 1
end

# Files to add
files_to_add = [
  # Core Database
  'FLEXR/Sources/Core/Database/WorkoutEntity+Extensions.swift',

  # Analytics Service (already exists, just need to ensure it's in Compile Sources)
  'FLEXR/Sources/Core/Services/AnalyticsService.swift',

  # Analytics Views
  'FLEXR/Sources/Features/Analytics/Views/AnalyticsContainerView.swift',
  'FLEXR/Sources/Features/Analytics/Views/AnalyticsDashboardView.swift',
  'FLEXR/Sources/Features/Analytics/Views/HeartRateAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/HyroxRunningAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/RecoveryAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/RunningWorkoutsView.swift',
  'FLEXR/Sources/Features/Analytics/Views/StationAnalyticsView.swift',
  'FLEXR/Sources/Features/Analytics/Workout/WorkoutHistoryView.swift'
]

puts "🔧 Restoring analytics files to Xcode project..."
added_count = 0
already_added = 0
not_found = 0

files_to_add.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)

  unless File.exist?(full_path)
    puts "⚠️  File not found: #{file_path}"
    not_found += 1
    next
  end

  # Check if file reference already exists
  file_ref = project.files.find { |f| f.path == file_path || f.real_path.to_s.end_with?(file_path) }

  if file_ref
    # File reference exists, check if it's in build phase
    if target.source_build_phase.files_references.include?(file_ref)
      puts "✓ Already in project: #{file_path}"
      already_added += 1
    else
      # Add to build phase
      target.source_build_phase.add_file_reference(file_ref)
      puts "✓ Added to build phase: #{file_path}"
      added_count += 1
    end
  else
    # Need to create file reference and add to group

    # Determine the group path from file path
    parts = file_path.split('/')
    group = project.main_group

    # Navigate to the correct group, creating if needed
    parts[0..-2].each do |part|
      existing_group = group.children.find { |child| child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.display_name == part }
      if existing_group
        group = existing_group
      else
        group = group.new_group(part, part)
      end
    end

    # Add file reference
    file_ref = group.new_reference(file_path)
    file_ref.last_known_file_type = 'sourcecode.swift'

    # Add to compile sources
    target.source_build_phase.add_file_reference(file_ref)

    puts "✓ Added new file: #{file_path}"
    added_count += 1
  end
end

# Save project
project.save

puts "\n📊 Summary:"
puts "   ✓ Added to build phase: #{added_count}"
puts "   ✓ Already in project: #{already_added}"
puts "   ⚠️  Not found: #{not_found}"
puts "\n✅ Analytics files restored successfully!"
