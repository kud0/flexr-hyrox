#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the FLEXR target
target = project.targets.find { |t| t.name == 'FLEXR' }

# Remove all broken references
project.main_group.recursive_children.each do |item|
  if item.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    if item.path && item.path.include?('FLEXR/Sources/Features/Analytics/FLEXR/Sources')
      puts "🗑️  Removing broken reference: #{item.path}"
      item.remove_from_project
    end
  end
end

# Find groups
features_group = project.main_group['FLEXR']['Sources']['Features']
analytics_group = features_group['Analytics'] || features_group.new_group('Analytics')
components_group = analytics_group['Components'] || analytics_group.new_group('Components')
hero_cards_group = analytics_group['HeroCards'] || analytics_group.new_group('HeroCards')
views_group = analytics_group['Views'] || analytics_group.new_group('Views')

# Set correct paths for groups
components_group.path = 'Components'
hero_cards_group.path = 'HeroCards'
views_group.path = 'Views'

# Component files - just filenames
component_files = {
  'HeroMetricCard.swift' => components_group,
  'MetricBreakdownCard.swift' => components_group,
  'TrendLineChart.swift' => components_group,
  'ContributionBar.swift' => components_group,
  'InsightBanner.swift' => components_group,
  'ReadinessHeroCard.swift' => hero_cards_group,
  'RacePredictionHeroCard.swift' => hero_cards_group,
  'WeeklyTrainingHeroCard.swift' => hero_cards_group,
  'AnalyticsHomeView.swift' => views_group
}

# Add files with correct paths
component_files.each do |filename, group|
  unless group.files.any? { |f| f.display_name == filename }
    file_ref = group.new_file(filename)
    target.add_file_references([file_ref])
    puts "✅ Added #{filename} to #{group.name}"
  else
    puts "⏭️  #{filename} already exists"
  end
end

project.save
puts "\n🎉 Fixed all analytics file paths!"
