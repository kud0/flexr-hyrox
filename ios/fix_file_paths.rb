#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'FLEXR' }

puts "🔧 Fixing file paths in Xcode project..."

# Remove incorrectly added files from build phase
compile_phase = target.source_build_phase

files_to_remove = []
compile_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  # Check if path has duplicated components
  if file_ref.real_path.to_s.include?('FLEXR/Sources/Core/Services/FLEXR/Sources') ||
     file_ref.real_path.to_s.include?('FLEXR/Sources/Features/FLEXR/Sources')
    puts "  ❌ Removing incorrectly added: #{file_ref.path}"
    files_to_remove << build_file
  end
end

files_to_remove.each do |build_file|
  compile_phase.remove_file_reference(build_file.file_ref)
end

# Remove file references from groups
def remove_bad_refs(group)
  group.files.each do |file_ref|
    if file_ref.real_path.to_s.include?('FLEXR/Sources/Core/Services/FLEXR/Sources') ||
       file_ref.real_path.to_s.include?('FLEXR/Sources/Features/FLEXR/Sources')
      puts "  🗑️  Removing bad reference: #{file_ref.path}"
      file_ref.remove_from_project
    end
  end

  group.groups.each do |subgroup|
    remove_bad_refs(subgroup)
  end
end

remove_bad_refs(project.main_group)

project.save

puts "\n✅ Removed bad file references."
puts "\nNow adding files with correct paths..."

# Now add files correctly
sources_group = project.main_group['FLEXR/Sources'] || project.main_group['FLEXR'].new_group('Sources')
core_group = sources_group['Core'] || sources_group.new_group('Core')
services_group = core_group['Services'] || core_group.new_group('Services')

features_group = sources_group['Features'] || sources_group.new_group('Features')
social_group = features_group['Social'] || features_group.new_group('Social')
gym_group = social_group['Gym'] || social_group.new_group('Gym')
friends_group = social_group['Friends'] || social_group.new_group('Friends')

# Service files - use filename only
service_files = [
  { name: 'GymService.swift', group: services_group },
  { name: 'RelationshipService.swift', group: services_group },
  { name: 'SocialService.swift', group: services_group }
]

# View files - use filename only
gym_view_files = [
  'GymSearchView.swift',
  'GymDetailView.swift',
  'GymMembersView.swift',
  'GymLeaderboardsView.swift',
  'GymActivityFeedView.swift'
]

friends_view_files = [
  'FriendsListView.swift'
]

# Add service files
puts "\n📂 Adding Service files:"
service_files.each do |file_info|
  existing = file_info[:group].files.find { |f| f.path == file_info[:name] }

  if existing.nil?
    file_ref = file_info[:group].new_reference(file_info[:name])
    target.add_file_references([file_ref])
    puts "  ✅ Added #{file_info[:name]}"
  else
    puts "  ℹ️  #{file_info[:name]} already exists"
  end
end

# Add gym view files
puts "\n📂 Adding Gym View files:"
gym_view_files.each do |filename|
  existing = gym_group.files.find { |f| f.path == filename }

  if existing.nil?
    file_ref = gym_group.new_reference(filename)
    target.add_file_references([file_ref])
    puts "  ✅ Added #{filename}"
  else
    puts "  ℹ️  #{filename} already exists"
  end
end

# Add friends view files
puts "\n📂 Adding Friends View files:"
friends_view_files.each do |filename|
  existing = friends_group.files.find { |f| f.path == filename }

  if existing.nil?
    file_ref = friends_group.new_reference(filename)
    target.add_file_references([file_ref])
    puts "  ✅ Added #{filename}"
  else
    puts "  ℹ️  #{filename} already exists"
  end
end

project.save

puts "\n🎉 File paths fixed! Project should build correctly now."
