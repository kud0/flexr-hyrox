#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

# Remove ALL analytics-related file references that have broken paths
to_remove = []
target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref
  
  if file_ref.path && (
    file_ref.path.include?('HeroMetricCard') ||
    file_ref.path.include?('MetricBreakdownCard') ||
    file_ref.path.include?('TrendLineChart') ||
    file_ref.path.include?('ContributionBar') ||
    file_ref.path.include?('InsightBanner') ||
    file_ref.path.include?('ReadinessHeroCard') ||
    file_ref.path.include?('RacePredictionHeroCard') ||
    file_ref.path.include?('WeeklyTrainingHeroCard') ||
    file_ref.path.include?('AnalyticsHomeView')
  )
    puts "🗑️  Removing: #{file_ref.path}"
    to_remove << build_file
  end
end

to_remove.each { |bf| bf.remove_from_project }

# Clean up file references
project.main_group.recursive_children.each do |item|
  if item.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    if item.path && (
      item.path.include?('HeroMetricCard') ||
      item.path.include?('MetricBreakdownCard') ||
      item.path.include?('TrendLineChart') ||
      item.path.include?('ContributionBar') ||
      item.path.include?('InsightBanner') ||
      item.path.include?('ReadinessHeroCard') ||
      item.path.include?('RacePredictionHeroCard') ||
      item.path.include?('WeeklyTrainingHeroCard') ||
      item.path.include?('AnalyticsHomeView')
    )
      puts "🗑️  Removing file ref: #{item.path}"
      item.remove_from_project
    end
  end
end

project.save
puts "\n✅ Cleaned up broken references"

# Reopen and add correctly
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

features_group = project.main_group['FLEXR']['Sources']['Features']
analytics_group = features_group['Analytics'] || features_group.new_group('Analytics')

# Create/find subgroups
components_group = analytics_group.children.find { |c| c.display_name == 'Components' }
components_group ||= analytics_group.new_group('Components', 'Components')

hero_cards_group = analytics_group.children.find { |c| c.display_name == 'HeroCards' }
hero_cards_group ||= analytics_group.new_group('HeroCards', 'HeroCards')

views_group = analytics_group.children.find { |c| c.display_name == 'Views' }
views_group ||= views_group = analytics_group['Views']

# Add files with just filenames
files_to_add = [
  ['HeroMetricCard.swift', components_group],
  ['MetricBreakdownCard.swift', components_group],
  ['TrendLineChart.swift', components_group],
  ['ContributionBar.swift', components_group],
  ['InsightBanner.swift', components_group],
  ['ReadinessHeroCard.swift', hero_cards_group],
  ['RacePredictionHeroCard.swift', hero_cards_group],
  ['WeeklyTrainingHeroCard.swift', hero_cards_group],
  ['AnalyticsHomeView.swift', views_group]
]

files_to_add.each do |filename, group|
  file_ref = group.new_file(filename)
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added #{filename}"
end

project.save
puts "\n🎉 All files added correctly!"
