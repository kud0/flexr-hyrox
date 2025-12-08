#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'FLEXR' }

# Find or create the Features/Social group structure
sources_group = project.main_group['FLEXR/Sources'] || project.main_group['FLEXR'].new_group('Sources')
features_group = sources_group['Features'] || sources_group.new_group('Features')
social_group = features_group['Social'] || features_group.new_group('Social')

# Create subgroups
gym_group = social_group['Gym'] || social_group.new_group('Gym')
friends_group = social_group['Friends'] || social_group.new_group('Friends')

# Gym view files
gym_files = [
  'FLEXR/Sources/Features/Social/Gym/GymSearchView.swift',
  'FLEXR/Sources/Features/Social/Gym/GymDetailView.swift',
  'FLEXR/Sources/Features/Social/Gym/GymMembersView.swift',
  'FLEXR/Sources/Features/Social/Gym/GymLeaderboardsView.swift',
  'FLEXR/Sources/Features/Social/Gym/GymActivityFeedView.swift'
]

# Friends view files
friends_files = [
  'FLEXR/Sources/Features/Social/Friends/FriendsListView.swift'
]

# Add gym files
puts "\n📂 Adding Gym Views:"
gym_files.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in the group
  existing_file = gym_group.files.find { |f| f.path == file_name }

  if existing_file.nil?
    # Add file reference
    file_ref = gym_group.new_file(file_path)

    # Add to target
    target.add_file_references([file_ref])

    puts "  ✅ Added #{file_name}"
  else
    puts "  ℹ️  #{file_name} already exists"
  end
end

# Add friends files
puts "\n📂 Adding Friends Views:"
friends_files.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in the group
  existing_file = friends_group.files.find { |f| f.path == file_name }

  if existing_file.nil?
    # Add file reference
    file_ref = friends_group.new_file(file_path)

    # Add to target
    target.add_file_references([file_ref])

    puts "  ✅ Added #{file_name}"
  else
    puts "  ℹ️  #{file_name} already exists"
  end
end

project.save

puts "\n🎉 Done! All social feature views added to Xcode project."
puts "\n📊 Summary:"
puts "  • #{gym_files.length} gym views"
puts "  • #{friends_files.length} friends views"
puts "  • Total: #{gym_files.length + friends_files.length} SwiftUI views"
