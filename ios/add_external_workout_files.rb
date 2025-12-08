#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the FLEXR target
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find groups
models_group = project.main_group['FLEXR']['Sources']['Core']['Models']
analytics_views_group = project.main_group['FLEXR']['Sources']['Features']['Analytics']['Views']

# Remove bad references first
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref&.path&.include?('FLEXR/Sources/Core/Models/FLEXR') ||
     build_file.file_ref&.path&.include?('FLEXR/Sources/Features/Analytics/Views/FLEXR')
    build_file.remove_from_project
    puts "🗑️  Removed bad reference: #{build_file.file_ref&.path}"
  end
end

# Clean up group references
models_group.files.each do |file_ref|
  if file_ref.path&.include?('FLEXR/Sources/Core/Models/FLEXR')
    file_ref.remove_from_project
    puts "🗑️  Removed bad model ref"
  end
end

analytics_views_group.files.each do |file_ref|
  if file_ref.path&.include?('FLEXR/Sources/Features/Analytics/Views/FLEXR')
    file_ref.remove_from_project
    puts "🗑️  Removed bad view ref"
  end
end

# Add model file with correct path
model_file = 'ExternalWorkout.swift'
unless models_group.files.any? { |f| f.path == model_file }
  file_ref = models_group.new_file(model_file)
  target.add_file_references([file_ref])
  puts "✅ Added #{model_file} to Models"
else
  puts "⏭️  #{model_file} already exists in Models"
end

# Add view file with correct path
view_file = 'AllActivityView.swift'
unless analytics_views_group.files.any? { |f| f.path == view_file }
  file_ref = analytics_views_group.new_file(view_file)
  target.add_file_references([file_ref])
  puts "✅ Added #{view_file} to Analytics/Views"
else
  puts "⏭️  #{view_file} already exists in Analytics/Views"
end

project.save
puts "✅ Project saved successfully"
