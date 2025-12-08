#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

flexr_target = project.targets.find { |t| t.name == 'FLEXR' }
sources_phase = flexr_target.source_build_phase

puts "🔍 Finding ALL files with doubled paths..."
puts

doubled_files = []

sources_phase.files.each do |build_file|
  next unless build_file.file_ref

  real_path = build_file.file_ref.real_path.to_s

  # Check for doubled FLEXR prefix
  if real_path.include?('/FLEXR/FLEXR/')
    doubled_files << {
      build_file: build_file,
      current_path: real_path,
      basename: File.basename(real_path)
    }
  end
end

puts "Found #{doubled_files.length} files with doubled paths:"
puts

doubled_files.each do |info|
  puts "  ❌ #{info[:basename]}"
  puts "     Current: #{info[:current_path]}"

  # Calculate correct path
  corrected = info[:current_path].sub('/FLEXR/FLEXR/', '/FLEXR/')
  puts "     Correct: #{corrected}"
  puts "     Exists: #{File.exist?(corrected)}"
  puts
end

puts "=" * 80
puts "Total doubled paths: #{doubled_files.length}"
