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

puts "🔍 Analyzing FLEXR target source files..."

# Get all build files in the sources build phase
sources_phase = flexr_target.source_build_phase
build_files = sources_phase.files

# Track files by basename
files_by_basename = Hash.new { |h, k| h[k] = [] }

build_files.each do |build_file|
  next unless build_file.file_ref

  file_ref = build_file.file_ref
  path = file_ref.real_path.to_s
  basename = File.basename(path)

  files_by_basename[basename] << {
    build_file: build_file,
    file_ref: file_ref,
    path: path
  }
end

# Find and remove duplicates
duplicates_removed = 0

files_by_basename.each do |basename, files|
  next if files.length <= 1

  puts "\n📦 Found #{files.length} instances of #{basename}:"
  files.each_with_index do |file, idx|
    puts "  #{idx + 1}. #{file[:path]}"
  end

  # Strategy: Keep the file with the longest/most specific path
  # Remove files with relative paths or shorter paths
  files_sorted = files.sort_by { |f| [f[:path].include?('/') ? 1 : 0, f[:path].length] }.reverse

  # Keep the first (most specific path), remove others
  to_keep = files_sorted.first
  to_remove = files_sorted[1..]

  puts "  ✅ Keeping: #{to_keep[:path]}"

  to_remove.each do |file|
    puts "  ❌ Removing: #{file[:path]}"
    sources_phase.remove_file_reference(file[:build_file])
    duplicates_removed += 1
  end
end

# Handle specific known duplicates in different directories
specific_duplicates = [
  {
    basename: 'VideoRecordingService.swift',
    keep: 'FLEXR/Sources/Core/Services/VideoRecordingService.swift',
    remove: 'FLEXR/Sources/Features/Video/VideoRecordingService.swift'
  },
  {
    basename: 'WorkoutDetailView.swift',
    keep: 'FLEXR/Sources/Features/Workout/WorkoutDetailView.swift',
    remove: 'FLEXR/Sources/Features/Training/WorkoutDetailView.swift'
  },
  {
    basename: 'GymActivityFeedView.swift',
    keep: 'FLEXR/Sources/Features/Analytics/Social/GymActivityFeedView.swift',
    remove: 'FLEXR/Sources/Features/Social/Gym/GymActivityFeedView.swift'
  }
]

puts "\n🎯 Handling specific duplicate files in different directories..."

specific_duplicates.each do |dup|
  matching_files = files_by_basename[dup[:basename]]
  next unless matching_files

  # Find the file to remove
  file_to_remove = matching_files.find { |f| f[:path].include?(dup[:remove]) }

  if file_to_remove
    puts "  ❌ Removing: #{file_to_remove[:path]}"
    sources_phase.remove_file_reference(file_to_remove[:build_file])
    duplicates_removed += 1
  end
end

puts "\n✅ Removed #{duplicates_removed} duplicate file references"

# Save project
project.save

puts "💾 Project saved successfully"
puts "\n🎉 Cleanup complete!"
