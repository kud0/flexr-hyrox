#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find Analytics/Components group
features_group = project.main_group['FLEXR']['Sources']['Features']
analytics_group = features_group['Analytics']
components_group = analytics_group['Components']

# Add the file
file_ref = components_group.new_file('AnalyticsCategoryCard.swift')
target.add_file_references([file_ref])

project.save
puts "✅ Added AnalyticsCategoryCard.swift"
