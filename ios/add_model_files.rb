#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

puts "📦 Adding model files to Xcode project..."

base_path = File.expand_path('FLEXR/Sources')

# Model files with absolute paths
model_files = [
  "#{base_path}/Core/Models/Gym.swift",
  "#{base_path}/Core/Models/Relationship.swift",
  "#{base_path}/Core/Models/SocialActivity.swift"
]

# Find the Models group
sources_group = project.main_group['FLEXR']&.[]('Sources')
core_group = sources_group&.[]('Core')
models_group = core_group&.[]('Models') || core_group&.new_group('Models')

# Add each model file
model_files.each do |file_path|
  filename = File.basename(file_path)

  # Check if already exists
  existing = models_group.files.find { |f| f.path&.include?(filename) }

  if existing
    puts "  ℹ️  #{filename} already in project"
  elsif File.exist?(file_path)
    # Create file reference with absolute path
    file_ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
    file_ref.path = file_path
    file_ref.source_tree = '<absolute>'
    file_ref.last_known_file_type = 'sourcecode.swift'

    # Add to Models group
    models_group << file_ref

    # Add to build phase
    target.add_file_references([file_ref])

    puts "  ✅ Added #{filename}"
  else
    puts "  ❌ File not found: #{file_path}"
  end
end

project.save

puts "\n🎉 Model files added successfully!"
puts "📊 Total: #{model_files.length} model files"
