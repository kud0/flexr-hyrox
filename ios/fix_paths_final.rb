#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'FLEXR' }

puts "🔧 Final fix for file paths..."

# Remove ALL social-related file references from build phase
compile_phase = target.source_build_phase
files_to_remove = []

compile_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  filename = file_ref.path
  if filename&.include?('GymService') ||
     filename&.include?('RelationshipService') ||
     filename&.include?('SocialService') ||
     filename&.include?('GymSearchView') ||
     filename&.include?('GymDetailView') ||
     filename&.include?('GymMembersView') ||
     filename&.include?('GymLeaderboardsView') ||
     filename&.include?('GymActivityFeedView') ||
     filename&.include?('FriendsListView')

    puts "  ❌ Removing: #{filename}"
    files_to_remove << build_file
  end
end

files_to_remove.each do |build_file|
  compile_phase.remove_file_reference(build_file.file_ref)
end

# Remove from groups
def remove_social_refs(group)
  group.files.to_a.each do |file_ref|
    filename = file_ref.path
    if filename&.include?('GymService') ||
       filename&.include?('RelationshipService') ||
       filename&.include?('SocialService') ||
       filename&.include?('GymSearchView') ||
       filename&.include?('GymDetailView') ||
       filename&.include?('GymMembersView') ||
       filename&.include?('GymLeaderboardsView') ||
       filename&.include?('GymActivityFeedView') ||
       filename&.include?('FriendsListView')

      puts "  🗑️  Removing ref: #{filename}"
      file_ref.remove_from_project
    end
  end

  group.groups.each do |subgroup|
    remove_social_refs(subgroup)
  end
end

remove_social_refs(project.main_group)

# Remove Social group entirely
sources_group = project.main_group['FLEXR/Sources']
features_group = sources_group['Features'] if sources_group
if features_group && features_group['Social']
  puts "  🗑️  Removing Social group"
  features_group['Social'].remove_from_project
end

project.save
puts "\n✅ Cleaned up old references."

# Now add files properly with full relative paths
puts "\n📂 Adding files with correct paths..."

sources_group = project.main_group['FLEXR/Sources'] || project.main_group['FLEXR'].new_group('Sources')
core_group = sources_group['Core'] || sources_group.new_group('Core')
services_group = core_group['Services'] || core_group.new_group('Services')

features_group = sources_group['Features'] || sources_group.new_group('Features')
social_group = features_group.new_group('Social')
social_group.path = 'Social'

gym_group = social_group.new_group('Gym')
gym_group.path = 'Gym'

friends_group = social_group.new_group('Friends')
friends_group.path = 'Friends'

# Add service files with proper paths
service_files = [
  { path: 'GymService.swift', group: services_group },
  { path: 'RelationshipService.swift', group: services_group },
  { path: 'SocialService.swift', group: services_group }
]

puts "\n📦 Adding Service files:"
service_files.each do |file_info|
  file_ref = file_info[:group].new_reference(file_info[:path])
  file_ref.name = file_info[:path]
  target.add_file_references([file_ref])
  puts "  ✅ #{file_info[:path]}"
end

# Add gym view files
gym_files = [
  'GymSearchView.swift',
  'GymDetailView.swift',
  'GymMembersView.swift',
  'GymLeaderboardsView.swift',
  'GymActivityFeedView.swift'
]

puts "\n📦 Adding Gym views:"
gym_files.each do |filename|
  file_ref = gym_group.new_reference(filename)
  file_ref.name = filename
  target.add_file_references([file_ref])
  puts "  ✅ #{filename}"
end

# Add friends view files
friends_files = ['FriendsListView.swift']

puts "\n📦 Adding Friends views:"
friends_files.each do |filename|
  file_ref = friends_group.new_reference(filename)
  file_ref.name = filename
  target.add_file_references([file_ref])
  puts "  ✅ #{filename}"
end

project.save

puts "\n🎉 All files added with correct paths!"
puts "\n📊 Summary:"
puts "  • 3 service files"
puts "  • 5 gym view files"
puts "  • 1 friends view file"
puts "  • Total: 9 Swift files"
