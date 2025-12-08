#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'FLEXR' }

puts "🔧 Comprehensive file path fix..."

# First, remove all social feature file references
compile_phase = target.source_build_phase
social_files = %w[
  GymService RelationshipService SocialService
  GymSearchView GymDetailView GymMembersView GymLeaderboardsView
  GymActivityFeedView FriendsListView
]

# Remove from build phase
files_to_remove = compile_phase.files.select do |build_file|
  file_ref = build_file.file_ref
  social_files.any? { |name| file_ref&.path&.include?(name) }
end

files_to_remove.each do |build_file|
  puts "  ❌ Removing #{build_file.file_ref.path} from build phase"
  compile_phase.remove_build_file(build_file)
end

# Remove from groups recursively
def remove_social_files(group, social_files)
  group.files.to_a.each do |file_ref|
    if social_files.any? { |name| file_ref.path&.include?(name) }
      puts "  🗑️  Removing #{file_ref.path} from project"
      file_ref.remove_from_project
    end
  end

  group.groups.each { |subgroup| remove_social_files(subgroup, social_files) }
end

remove_social_files(project.main_group, social_files)

# Remove Social groups
sources_group = project.main_group['FLEXR']&.[]('Sources')
features_group = sources_group&.[]('Features')
features_group&.[]('Social')&.remove_from_project if features_group&.[]('Social')

project.save
puts "\n✅ Cleaned up all old references\n"

# Now manually add files to the project with absolute paths
puts "📂 Adding files with absolute paths...\n"

base_path = File.expand_path('FLEXR/Sources')

# Service files
service_files = [
  "#{base_path}/Core/Services/GymService.swift",
  "#{base_path}/Core/Services/RelationshipService.swift",
  "#{base_path}/Core/Services/SocialService.swift"
]

# View files
view_files = [
  "#{base_path}/Features/Social/Gym/GymSearchView.swift",
  "#{base_path}/Features/Social/Gym/GymDetailView.swift",
  "#{base_path}/Features/Social/Gym/GymMembersView.swift",
  "#{base_path}/Features/Social/Gym/GymLeaderboardsView.swift",
  "#{base_path}/Features/Social/Gym/GymActivityFeedView.swift",
  "#{base_path}/Features/Social/Friends/FriendsListView.swift"
]

all_files = service_files + view_files

# Add files to target using absolute paths
all_files.each do |file_path|
  if File.exist?(file_path)
    # Create file reference with absolute path
    file_ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
    file_ref.path = file_path
    file_ref.source_tree = '<absolute>'
    file_ref.last_known_file_type = 'sourcecode.swift'

    # Add to appropriate group based on path
    if file_path.include?('Services')
      core_group = sources_group['Core'] || sources_group.new_group('Core')
      services_group = core_group['Services'] || core_group.new_group('Services')
      services_group << file_ref
    else
      features_group = sources_group['Features'] || sources_group.new_group('Features')
      social_group = features_group['Social'] || features_group.new_group('Social')

      if file_path.include?('Gym')
        gym_group = social_group['Gym'] || social_group.new_group('Gym')
        gym_group << file_ref
      elsif file_path.include?('Friends')
        friends_group = social_group['Friends'] || social_group.new_group('Friends')
        friends_group << file_ref
      end
    end

    # Add to build phase
    target.add_file_references([file_ref])

    puts "  ✅ Added #{File.basename(file_path)}"
  else
    puts "  ❌ File not found: #{file_path}"
  end
end

project.save

puts "\n🎉 All files added with absolute paths!"
puts "📊 Total: #{all_files.length} Swift files"
