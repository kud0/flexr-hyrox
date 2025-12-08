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

puts "🔧 Rebuilding Compile Sources phase..."

# Get all build files in the sources build phase
sources_phase = flexr_target.source_build_phase
build_files = sources_phase.files.dup

# Track files we want to keep (deduplicated)
files_to_keep = {}

build_files.each do |build_file|
  next unless build_file.file_ref

  file_ref = build_file.file_ref
  display_name = file_ref.display_name || file_ref.path || "Unknown"
  path = file_ref.real_path.to_s

  # Skip if we already have this basename
  if files_to_keep.key?(display_name)
    existing_path = files_to_keep[display_name][:path]

    # Decide which one to keep
    should_replace = false

    # If existing has doubled path, replace it
    if existing_path.include?('/FLEXR/Sources/FLEXR/Sources/') && !path.include?('/FLEXR/Sources/FLEXR/Sources/')
      should_replace = true
    end

    # If both don't have doubled path, prefer shorter path
    if !existing_path.include?('/FLEXR/Sources/FLEXR/Sources/') && !path.include?('/FLEXR/Sources/FLEXR/Sources/')
      should_replace = path.length < existing_path.length
    end

    # Special case preferences
    if display_name == 'VideoRecordingService.swift' && path.include?('/Core/Services/') && existing_path.include?('/Features/Video/')
      should_replace = true
    end

    if display_name == 'WorkoutDetailView.swift' && path.include?('/Features/Workout/') && existing_path.include?('/Features/Training/')
      should_replace = true
    end

    if display_name == 'GymActivityFeedView.swift' && path.include?('/Analytics/Social/') && existing_path.include?('/Social/Gym/')
      should_replace = true
    end

    if should_replace
      puts "  🔄 Replacing #{display_name}: #{existing_path} → #{path}"
      files_to_keep[display_name] = {
        build_file: build_file,
        file_ref: file_ref,
        path: path
      }
    else
      puts "  ⏭  Skipping duplicate #{display_name}: #{path}"
    end
  else
    # First time seeing this basename, keep it
    files_to_keep[display_name] = {
      build_file: build_file,
      file_ref: file_ref,
      path: path
    }
  end
end

puts "\n🗑️  Clearing Compile Sources phase..."
# Clear all files
sources_phase.files.clear

puts "➕  Adding deduplicated files back..."
# Add back only the files we want to keep
files_to_keep.values.each do |file_info|
  sources_phase.files << file_info[:build_file]
end

puts "\n✅ Removed #{build_files.length - files_to_keep.length} duplicate references"
puts "📊 Total files in Compile Sources: #{sources_phase.files.length}"

# Save project
project.save

puts "💾 Project saved successfully"
puts "\n🎉 Rebuild complete!"
