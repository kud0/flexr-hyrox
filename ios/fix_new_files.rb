#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'FLEXR' }
sources_phase = target.source_build_phase

# Remove ALL references to these files first
files_to_fix = ['ExternalWorkout.swift', 'AllActivityView.swift']

files_to_fix.each do |file_name|
  sources_phase.files.select { |bf| bf.file_ref&.path&.include?(file_name) }.each do |bf|
    puts "🗑️  Removing: #{bf.file_ref&.path}"
    bf.remove_from_project
  end
end

# Also remove any file references in groups
def remove_file_refs_recursive(group, file_name)
  group.files.select { |f| f.path&.include?(file_name) }.each do |f|
    puts "🗑️  Removing group ref: #{f.path}"
    f.remove_from_project
  end
  group.groups.each { |g| remove_file_refs_recursive(g, file_name) }
end

files_to_fix.each do |file_name|
  remove_file_refs_recursive(project.main_group, file_name)
end

project.save
puts "✅ Cleaned up old references"

# Now add them correctly
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find the correct groups
models_group = project.main_group['FLEXR']['Sources']['Core']['Models']
views_group = project.main_group['FLEXR']['Sources']['Features']['Analytics']['Views']

# Add ExternalWorkout.swift to Models
file_ref = models_group.new_file('ExternalWorkout.swift')
target.add_file_references([file_ref])
puts "✅ Added ExternalWorkout.swift"

# Add AllActivityView.swift to Views
file_ref = views_group.new_file('AllActivityView.swift')
target.add_file_references([file_ref])
puts "✅ Added AllActivityView.swift"

project.save
puts "✅ Project saved"
