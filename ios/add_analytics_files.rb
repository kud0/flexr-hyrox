#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the FLEXR target
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find or create Analytics groups
features_group = project.main_group['FLEXR']['Sources']['Features']
analytics_group = features_group['Analytics'] || features_group.new_group('Analytics')

# Create subgroups if they don't exist
components_group = analytics_group['Components'] || analytics_group.new_group('Components')
hero_cards_group = analytics_group['HeroCards'] || analytics_group.new_group('HeroCards')
views_group = analytics_group['Views'] || analytics_group.new_group('Views')

# Component files
component_files = [
  'FLEXR/Sources/Features/Analytics/Components/HeroMetricCard.swift',
  'FLEXR/Sources/Features/Analytics/Components/MetricBreakdownCard.swift',
  'FLEXR/Sources/Features/Analytics/Components/TrendLineChart.swift',
  'FLEXR/Sources/Features/Analytics/Components/ContributionBar.swift',
  'FLEXR/Sources/Features/Analytics/Components/InsightBanner.swift'
]

# Hero card files
hero_files = [
  'FLEXR/Sources/Features/Analytics/HeroCards/ReadinessHeroCard.swift',
  'FLEXR/Sources/Features/Analytics/HeroCards/RacePredictionHeroCard.swift',
  'FLEXR/Sources/Features/Analytics/HeroCards/WeeklyTrainingHeroCard.swift'
]

# View files
view_files = [
  'FLEXR/Sources/Features/Analytics/Views/AnalyticsHomeView.swift'
]

# Add component files
component_files.each do |file_path|
  file_name = File.basename(file_path)
  unless components_group.files.any? { |f| f.path == file_path }
    file_ref = components_group.new_file(file_path)
    target.add_file_references([file_ref])
    puts "✅ Added #{file_name}"
  else
    puts "⏭️  #{file_name} already exists"
  end
end

# Add hero card files
hero_files.each do |file_path|
  file_name = File.basename(file_path)
  unless hero_cards_group.files.any? { |f| f.path == file_path }
    file_ref = hero_cards_group.new_file(file_path)
    target.add_file_references([file_ref])
    puts "✅ Added #{file_name}"
  else
    puts "⏭️  #{file_name} already exists"
  end
end

# Add view files
view_files.each do |file_path|
  file_name = File.basename(file_path)
  unless views_group.files.any? { |f| f.path == file_path }
    file_ref = views_group.new_file(file_path)
    target.add_file_references([file_ref])
    puts "✅ Added #{file_name}"
  else
    puts "⏭️  #{file_name} already exists"
  end
end

project.save
puts "\n🎉 All analytics files added to Xcode project!"
