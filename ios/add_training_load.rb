#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find Analytics/Views group
features_group = project.main_group['FLEXR']['Sources']['Features']
analytics_group = features_group['Analytics']
views_group = analytics_group['Views']

# Add the file
file_ref = views_group.new_file('TrainingLoadDetailView.swift')
target.add_file_references([file_ref])

project.save
puts "✅ Added TrainingLoadDetailView.swift"
