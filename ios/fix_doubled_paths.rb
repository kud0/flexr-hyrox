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

puts "🔍 Fixing doubled paths in FLEXR target..."

# Get all build files in the sources build phase
sources_phase = flexr_target.source_build_phase
build_files = sources_phase.files.dup # Create a copy to iterate

removed_count = 0

build_files.each do |build_file|
  next unless build_file.file_ref

  file_ref = build_file.file_ref
  path = file_ref.real_path.to_s

  # Check if path contains the doubled "FLEXR/Sources/FLEXR/Sources/" pattern
  if path.include?('/FLEXR/Sources/FLEXR/Sources/')
    puts "❌ Removing doubled path: #{path}"
    sources_phase.remove_file_reference(build_file)
    removed_count += 1
  end
end

puts "\n✅ Removed #{removed_count} files with doubled paths"

# Save project
project.save

puts "💾 Project saved successfully"
puts "\n🎉 Path fix complete!"
