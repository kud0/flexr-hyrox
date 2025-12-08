#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find the Workout/Active group
features_group = project.main_group['FLEXR']['Sources']['Features']
workout_group = features_group['Workout']
active_group = workout_group['Active']

# Add the file
file_ref = active_group.new_file('ActiveWorkoutBoardView.swift')
target.add_file_references([file_ref])

project.save
puts "✅ Added ActiveWorkoutBoardView.swift"
