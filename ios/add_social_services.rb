#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find or create the Core/Services group
sources_group = project.main_group['FLEXR/Sources'] || project.main_group['FLEXR'].new_group('Sources')
core_group = sources_group['Core'] || sources_group.new_group('Core')
services_group = core_group['Services'] || core_group.new_group('Services')

# Service files to add
service_files = [
  'FLEXR/Sources/Core/Services/GymService.swift',
  'FLEXR/Sources/Core/Services/RelationshipService.swift',
  'FLEXR/Sources/Core/Services/SocialService.swift'
]

service_files.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in the group
  existing_file = services_group.files.find { |f| f.path == file_name }

  if existing_file.nil?
    # Add file reference
    file_ref = services_group.new_file(file_path)

    # Add to target
    target.add_file_references([file_ref])

    puts "✅ Added #{file_name}"
  else
    puts "ℹ️  #{file_name} already exists"
  end
end

project.save

puts "\n🎉 Done! Social service files added to Xcode project."
