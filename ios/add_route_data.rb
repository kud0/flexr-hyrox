require 'xcodeproj'

project = Xcodeproj::Project.open('FLEXR.xcodeproj')
main_target = project.targets.find { |t| t.name == 'FLEXR' }

# Find or create Models group
models_group = project.main_group.find_subpath('FLEXR/Sources/Core/Models', true)

# Add RouteData.swift
file_ref = models_group.new_file('FLEXR/Sources/Core/Models/RouteData.swift')
file_ref.source_tree = 'SOURCE_ROOT'
main_target.add_file_references([file_ref])

project.save
puts "✓ Added RouteData.swift to project"
