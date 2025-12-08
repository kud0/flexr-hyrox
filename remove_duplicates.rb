#!/usr/bin/env ruby
# Script to remove duplicate Mission Control file references from Xcode project
# Requires: gem install xcodeproj

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔍 Removing duplicate Mission Control file references..."

# Find FLEXR target
target = project.targets.find { |t| t.name == 'FLEXR' }

if target.nil?
  puts "❌ Could not find FLEXR target"
  exit 1
end

# Get the compile sources build phase
sources_phase = target.source_build_phase

# Track seen files to detect duplicates
seen_files = {}
duplicates_removed = 0

# Iterate through build files and remove duplicates
sources_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  file_path = file_ref.real_path.to_s

  if seen_files[file_path]
    # This is a duplicate - remove it
    puts "   ✓ Removing duplicate: #{file_ref.display_name}"
    sources_phase.files.delete(build_file)
    duplicates_removed += 1
  else
    seen_files[file_path] = true
  end
end

# Save project
project.save

puts "\n✅ Removed #{duplicates_removed} duplicate file reference(s)!"
puts "🚀 Project cleaned and ready to build!"
