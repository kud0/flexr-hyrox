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

puts "🔧 Final cleanup of duplicate files..."

# Get all build files in the sources build phase
sources_phase = flexr_target.source_build_phase
build_files = sources_phase.files.dup

removed_count = 0

# Track files by basename
files_by_basename = Hash.new { |h, k| h[k] = [] }

build_files.each do |build_file|
  next unless build_file.file_ref

  file_ref = build_file.file_ref
  display_name = file_ref.display_name || file_ref.path || "Unknown"
  path = file_ref.real_path.to_s

  files_by_basename[display_name] << {
    build_file: build_file,
    file_ref: file_ref,
    display_name: display_name,
    path: path
  }
end

# Process duplicates
duplicates = files_by_basename.select { |_, files| files.length > 1 }

duplicates.each do |basename, files|
  puts "\n📄 Processing #{basename} (#{files.length} instances):"

  # Sort files by path:
  # 1. Prefer paths WITHOUT doubled "FLEXR/Sources/FLEXR/Sources/" pattern
  # 2. Among remaining, prefer shorter paths
  # 3. For specific cases, prefer certain directories

  files_sorted = files.sort_by do |f|
    path = f[:path]
    score = 0

    # Heavily penalize paths with doubled FLEXR/Sources
    if path.include?('/FLEXR/Sources/FLEXR/Sources/')
      score += 1000
    end

    # Add path length as secondary sort
    score += path.length

    # For VideoRecordingService, prefer Core/Services over Features/Video
    if basename == 'VideoRecordingService.swift' && path.include?('/Features/Video/')
      score += 500
    end

    # For WorkoutDetailView, prefer Features/Workout over Features/Training
    if basename == 'WorkoutDetailView.swift' && path.include?('/Features/Training/')
      score += 500
    end

    # For GymActivityFeedView, prefer Features/Analytics/Social over Features/Social/Gym
    if basename == 'GymActivityFeedView.swift' && path.include?('/Features/Social/Gym/')
      score += 500
    end

    score
  end

  # Keep the first (lowest score), remove others
  to_keep = files_sorted.first
  to_remove = files_sorted[1..]

  puts "  ✅ Keeping: #{to_keep[:path]}"

  to_remove.each do |file|
    puts "  ❌ Removing: #{file[:path]}"
    sources_phase.remove_file_reference(file[:build_file])
    removed_count += 1
  end
end

puts "\n" + "=" * 80
puts "✅ Removed #{removed_count} duplicate file references"

# Save project
project.save

puts "💾 Project saved successfully"
puts "\n🎉 Final cleanup complete!"
