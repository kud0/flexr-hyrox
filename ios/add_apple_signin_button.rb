#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

flexr_target = project.targets.find { |t| t.name == 'FLEXR' }
flexr_group = project.main_group.find_subpath('FLEXR', true)

file_path = 'Sources/UI/Components/AppleSignInButton.swift'
absolute_path = File.join(Dir.pwd, 'FLEXR', file_path)

if File.exist?(absolute_path)
  file_ref = flexr_group.new_reference(absolute_path)
  flexr_target.source_build_phase.add_file_reference(file_ref)

  project.save
  puts "✅ Added AppleSignInButton.swift to FLEXR target"
else
  puts "❌ File not found: #{file_path}"
end
