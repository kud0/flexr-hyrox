require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find FLEXRWatch Watch App target
watch_target = project.targets.find { |t| t.name == 'FLEXRWatch Watch App' }

unless watch_target
  puts "Error: FLEXRWatch Watch App target not found"
  exit 1
end

# Find or create Services group in FLEXRWatch
watch_group = project.main_group.find_subpath('FLEXRWatch/Sources/Services', true)

# Add the new file
file_path = 'FLEXRWatch/Sources/Services/WatchPlanModels.swift'
file_ref = watch_group.new_file(file_path)
file_ref.source_tree = 'SOURCE_ROOT'

# Add to target
watch_target.add_file_references([file_ref])

project.save

puts "✓ Added WatchPlanModels.swift to FLEXRWatch Watch App target"
