#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files to add
new_files = [
  'FLEXR/Sources/Features/Analytics/Views/RunningHistoryView.swift',
  'FLEXR/Sources/Features/Analytics/Views/RunningStatsView.swift'
]

# Find the FLEXR target
target = project.targets.find { |t| t.name == 'FLEXR' }
unless target
  puts "❌ Error: FLEXR target not found"
  exit 1
end

# Find the Analytics/Views group
main_group = project.main_group
flexr_group = main_group['FLEXR']
unless flexr_group
  puts "❌ Error: FLEXR group not found"
  exit 1
end

sources_group = flexr_group['Sources']
unless sources_group
  puts "❌ Error: Sources group not found"
  exit 1
end

features_group = sources_group['Features']
unless features_group
  puts "❌ Error: Features group not found"
  exit 1
end

analytics_group = features_group['Analytics']
unless analytics_group
  puts "❌ Error: Analytics group not found"
  exit 1
end

views_group = analytics_group['Views']
unless views_group
  puts "❌ Error: Analytics/Views group not found"
  exit 1
end

# Add files to project
added_count = 0
new_files.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in group
  existing_file = views_group.files.find { |f| f.path == file_name }
  if existing_file
    puts "⚠️  #{file_name} already exists in project, skipping"
    next
  end

  # Add file reference to group
  file_ref = views_group.new_reference(file_path)

  # Add to target
  target.add_file_references([file_ref])

  puts "✅ Added #{file_name} to project"
  added_count += 1
end

# Save project
project.save

if added_count > 0
  puts "\n✅ Successfully added #{added_count} file(s) to FLEXR.xcodeproj"
  puts "📦 Files added to Analytics/Views group"
  puts "🎯 Files added to FLEXR target"
else
  puts "\n✅ All files already in project"
end
