#!/usr/bin/env ruby

# Add remaining analytics service files

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
  'FLEXR/Sources/Core/Services/WorkoutAnalyticsService.swift',
  'FLEXR/Sources/Core/Services/WorkoutIntegrationService.swift'
]

puts "🔧 Adding remaining analytics service files..."

files_to_add.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)
  unless File.exist?(full_path)
    puts "   ⚠️  Not found: #{file_path}"
    next
  end

  # Check if already added
  existing = project.files.find { |f| f.path&.include?(File.basename(file_path)) }
  if existing && target.source_build_phase.files_references.include?(existing)
    puts "   ✓ Already added: #{file_path}"
    next
  end

  # Remove any existing references first
  project.files.each do |f|
    if f.path&.include?(File.basename(file_path))
      f.remove_from_project
    end
  end

  # Navigate to group
  parts = file_path.split('/')
  group = project.main_group

  parts[0..-2].each do |part_name|
    child = group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == part_name }
    group = child || group.new_group(part_name, part_name)
  end

  # Add file reference
  file_ref = group.new_reference(parts.last)
  file_ref.set_source_tree('<group>')
  file_ref.set_last_known_file_type('sourcecode.swift')

  # Add to compile sources
  target.source_build_phase.add_file_reference(file_ref)

  puts "   ✓ Added: #{file_path}"
end

project.save

puts "\n✅ Analytics service files added!"
