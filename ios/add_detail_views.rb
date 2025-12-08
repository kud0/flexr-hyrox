#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find the Analytics/Views group
features_group = project.main_group['FLEXR']['Sources']['Features']
analytics_group = features_group['Analytics'] || features_group.new_group('Analytics')
views_group = analytics_group['Views'] || analytics_group.new_group('Views')

# Set correct path for Views group
views_group.path = 'Views'

# Detail view files to add
detail_views = [
  'ReadinessDetailView.swift',
  'RacePredictionTimelineView.swift',
  'WeeklyTrainingDetailView.swift'
]

detail_views.each do |filename|
  # Check if file already exists in group
  unless views_group.files.any? { |f| f.display_name == filename }
    file_ref = views_group.new_file(filename)
    target.add_file_references([file_ref])
    puts "✅ Added #{filename}"
  else
    puts "⏭️  #{filename} already exists"
  end
end

project.save
puts "\n🎉 All detail views added to Xcode project!"
