require 'xcodeproj'

project = Xcodeproj::Project.open('FLEXR.xcodeproj')

# Find FLEXRWatch Watch App target
watch_target = project.targets.find { |t| t.name == 'FLEXRWatch Watch App' }

unless watch_target
  puts "Error: FLEXRWatch Watch App target not found"
  exit 1
end

# Add compiler flag to disable strict concurrency for WatchPlanService
watch_target.build_configurations.each do |config|
  flags = config.build_settings['OTHER_SWIFT_FLAGS'] || '$(inherited)'
  flags = [flags] unless flags.is_a?(Array)
  
  # Add flag to suppress strict concurrency warnings
  unless flags.include?('-Xfrontend')
    flags << '-Xfrontend'
    flags << '-warn-concurrency'
  end
  
  config.build_settings['OTHER_SWIFT_FLAGS'] = flags
end

project.save

puts "✓ Updated FLEXRWatch Watch App build settings to reduce concurrency warnings"
