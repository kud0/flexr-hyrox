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

puts "🔧 Fixing file reference paths..."

# Get sources phase
sources_phase = flexr_target.source_build_phase

fixed_count = 0
not_fixed = 0

sources_phase.files.each do |build_file|
  next unless build_file.file_ref

  file_ref = build_file.file_ref
  current_path = file_ref.real_path.to_s

  # Check if path has the doubled prefix
  if current_path.include?('/FLEXR/Sources/FLEXR/Sources/')
    # Remove the doubled "FLEXR/Sources/" prefix
    corrected_path = current_path.sub('/FLEXR/Sources/FLEXR/Sources/', '/FLEXR/Sources/')

    # Check if corrected path exists
    if File.exist?(corrected_path)
      # Update the file reference path
      # We need to set the path relative to the FLEXR group
      relative_path = corrected_path.sub(%r{.*/FLEXR/}, '')

      file_ref.path = relative_path

      puts "  ✅ Fixed: #{File.basename(corrected_path)}"
      puts "     From: #{current_path}"
      puts "     To:   #{corrected_path}"
      fixed_count += 1
    else
      puts "  ❌ Can't fix #{File.basename(current_path)} - corrected path doesn't exist"
      puts "     Tried: #{corrected_path}"
      not_fixed += 1
    end
  end
end

puts "\n" + "=" * 80
puts "✅ Fixed #{fixed_count} file references"
puts "❌ Couldn't fix #{not_fixed} file references" if not_fixed > 0

# Save project
project.save

puts "💾 Project saved successfully"
puts "\n🎉 File references updated!"
