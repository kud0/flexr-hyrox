#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

flexr_target = project.targets.find { |t| t.name == 'FLEXR' }

puts "🔍 Checking Supabase framework linking..."
puts

# Check frameworks phase
frameworks_phase = flexr_target.frameworks_build_phase
puts "📦 Frameworks linked to FLEXR:"
frameworks_phase.files.each do |file|
  if file.file_ref
    puts "  - #{file.file_ref.display_name}"
  end
end

puts "\n🔗 Package product dependencies:"
flexr_target.package_product_dependencies.each do |dep|
  puts "  - #{dep.product_name} (from #{dep.package.name})"
end
