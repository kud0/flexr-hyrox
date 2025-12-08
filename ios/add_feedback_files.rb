#!/usr/bin/env ruby
# Add feedback files to Xcode project

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find FLEXR target
flexr_target = project.targets.find { |t| t.name == 'FLEXR' }
raise "FLEXR target not found" unless flexr_target

# Find the groups
models_group = project.main_group.find_subpath('FLEXR/Sources/Core/Models', false)
services_group = project.main_group.find_subpath('FLEXR/Sources/Core/Services', false)
profile_group = project.main_group.find_subpath('FLEXR/Sources/Features/Profile', false)

raise "Models group not found" unless models_group
raise "Services group not found" unless services_group
raise "Profile group not found" unless profile_group

# First, remove any bad references we created
[models_group, services_group, profile_group].each do |group|
  bad_refs = group.files.select { |f| f.path && f.path.include?('FLEXR/Sources') }
  bad_refs.each do |ref|
    puts "Removing bad reference: #{ref.path}"
    ref.remove_from_project
  end
end

project.save
puts "Cleaned up bad references"

# Re-open project
project = Xcodeproj::Project.open(project_path)
flexr_target = project.targets.find { |t| t.name == 'FLEXR' }

models_group = project.main_group.find_subpath('FLEXR/Sources/Core/Models', false)
services_group = project.main_group.find_subpath('FLEXR/Sources/Core/Services', false)
profile_group = project.main_group.find_subpath('FLEXR/Sources/Features/Profile', false)

# Files to add - use just the filename since the group provides the path
files_to_add = [
  { name: 'UserFeedbackRequest.swift', group: models_group },
  { name: 'UserFeedbackService.swift', group: services_group },
  { name: 'FeedbackView.swift', group: profile_group }
]

files_to_add.each do |file_info|
  name = file_info[:name]
  group = file_info[:group]

  # Check if already exists
  existing = group.files.find { |f| f.path == name }
  if existing
    puts "Already exists: #{name}"
    next
  end

  # Add file reference with just the filename
  file_ref = group.new_file(name)

  # Add to target's compile sources
  flexr_target.source_build_phase.add_file_reference(file_ref)

  puts "Added: #{name}"
end

project.save
puts "Project saved successfully!"
