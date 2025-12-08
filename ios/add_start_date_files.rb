#!/usr/bin/env ruby

# Script to add start date selection files to FLEXR Xcode project
# Run with: ruby add_start_date_files.rb

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the FLEXR iOS target (not the watch target)
target = project.targets.find { |t| t.name == 'FLEXR' }
puts "📱 Target: #{target.name}"

# Find the FLEXR group
flexr_group = project.main_group['FLEXR']
puts "📂 Found FLEXR group"

# Files to add
files_to_add = [
  'StartDateSelectionView.swift',
  'StartDatePageView.swift'
]

puts "\n📦 Adding start date files..."
files_to_add.each do |file_name|
  relative_path = "Sources/Features/Onboarding/#{file_name}"
  actual_path = "FLEXR/#{relative_path}"

  if File.exist?(actual_path)
    # Check if file already exists in project
    existing = flexr_group.files.find { |f| f.path&.include?(file_name) }
    if existing
      puts "  ⏩ #{file_name} already in project, skipping"
      next
    end

    # Create file reference with correct path
    file_ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
    file_ref.path = relative_path
    file_ref.name = file_name
    file_ref.source_tree = '<group>'
    file_ref.last_known_file_type = 'sourcecode.swift'
    file_ref.include_in_index = '1'

    # Add to group
    flexr_group << file_ref

    # Add to target's source build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "  ✅ Added #{file_name}"
  else
    puts "  ⚠️  File not found: #{actual_path}"
  end
end

# Save the project
puts "\n💾 Saving project..."
project.save

puts "\n✨ Done!"
