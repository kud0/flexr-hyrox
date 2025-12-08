#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

flexr_target = project.targets.find { |t| t.name == 'FLEXR' }
unless flexr_target
  puts "❌ FLEXR target not found"
  exit 1
end

puts "🧹 Removing files with doubled paths and re-adding with correct paths..."

sources_phase = flexr_target.source_build_phase
flexr_group = project.main_group.find_subpath('FLEXR', true)

removed_count = 0
readded_count = 0

# Get all build files
build_files_to_remove = []

sources_phase.files.each do |build_file|
  next unless build_file.file_ref

  real_path = build_file.file_ref.real_path.to_s

  # Check if path has doubled FLEXR/Sources
  if real_path.include?('/FLEXR/Sources/FLEXR/Sources/')
    build_files_to_remove << build_file
  end
end

puts "Found #{build_files_to_remove.length} files with doubled paths"

# Remove these build files
build_files_to_remove.each do |build_file|
  real_path = build_file.file_ref.real_path.to_s
  basename = File.basename(real_path)

  # Remove the build file
  sources_phase.files.delete(build_file)

  # Also remove the file reference
  build_file.file_ref.remove_from_project

  puts "  🗑  Removed: #{basename}"
  removed_count += 1

  # Find correct path
  corrected_path = real_path.sub('/FLEXR/Sources/FLEXR/Sources/', '/FLEXR/Sources/')

  if File.exist?(corrected_path)
    # Add it back with correct path
    file_ref = flexr_group.new_reference(corrected_path)
    sources_phase.add_file_reference(file_ref)

    puts "  ✅ Re-added: #{basename} (#{corrected_path})"
    readded_count += 1
  else
    puts "  ❌ Could not find corrected path: #{corrected_path}"
  end
end

puts "\n" + "=" * 80
puts "🗑  Removed #{removed_count} files with doubled paths"
puts "✅ Re-added #{readded_count} files with correct paths"

project.save

puts "💾 Project saved successfully"
puts "\n🎉 File paths fixed!"
