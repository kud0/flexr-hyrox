#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find FLEXR target
flexr_target = project.targets.find { |t| t.name == 'FLEXR' }

unless flexr_target
  puts "❌ FLEXR target not found"
  exit 1
end

puts "🔧 Fixing file reference paths (v3)..."

# Get sources phase
sources_phase = flexr_target.source_build_phase

fixed_count = 0

sources_phase.files.each do |build_file|
  next unless build_file.file_ref

  file_ref = build_file.file_ref
  current_path = file_ref.real_path.to_s

  # Check if path is wrong (doesn't exist)
  unless File.exist?(current_path)
    basename = File.basename(current_path)

    # Search for the file in FLEXR/Sources
    found = `find FLEXR/Sources -name "#{basename}" -type f 2>/dev/null`.strip.split("\n").first

    if found && File.exist?(found)
      # Set absolute path
      file_ref.path = found

      puts "  ✅ Fixed: #{basename}"
      puts "     To: #{found}"
      fixed_count += 1
    else
      puts "  ❌ Couldn't find: #{basename}"
    end
  end
end

puts "\n" + "=" * 80
puts "✅ Fixed #{fixed_count} file references"

# Save project
project.save

puts "💾 Project saved successfully"
puts "\n🎉 All file paths fixed!"
