#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

flexr_target = project.targets.find { |t| t.name == 'FLEXR' }
sources_phase = flexr_target.source_build_phase
flexr_group = project.main_group.find_subpath('FLEXR', true)

puts "🔍 Finding files with doubled /FLEXR/FLEXR/ paths..."

build_files_to_remove = []

sources_phase.files.each do |build_file|
  next unless build_file.file_ref

  real_path = build_file.file_ref.real_path.to_s

  # Check for doubled FLEXR prefix
  if real_path.include?('/FLEXR/FLEXR/')
    build_files_to_remove << {
      build_file: build_file,
      current_path: real_path,
      basename: File.basename(real_path)
    }
  end
end

puts "Found #{build_files_to_remove.length} files to fix"
puts

# Remove and re-add each file
build_files_to_remove.each do |info|
  puts "  Fixing: #{info[:basename]}"
  puts "    Old: #{info[:current_path]}"

  # Remove from project
  sources_phase.files.delete(info[:build_file])
  info[:build_file].file_ref.remove_from_project

  # Calculate correct path
  corrected_path = info[:current_path].sub('/FLEXR/FLEXR/', '/FLEXR/')
  puts "    New: #{corrected_path}"

  # Re-add with correct path
  if File.exist?(corrected_path)
    file_ref = flexr_group.new_reference(corrected_path)
    sources_phase.add_file_reference(file_ref)
    puts "    ✅ Fixed"
  else
    puts "    ❌ File not found at corrected path"
  end
  puts
end

project.save
puts "✅ Project saved with #{build_files_to_remove.length} files fixed"
