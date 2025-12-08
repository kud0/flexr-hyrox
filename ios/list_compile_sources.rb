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

puts "📦 Files in FLEXR Compile Sources phase:"
puts "=" * 80

# Get all build files in the sources build phase
sources_phase = flexr_target.source_build_phase
build_files = sources_phase.files

# Track files by basename
files_by_basename = Hash.new { |h, k| h[k] = [] }

build_files.each do |build_file|
  next unless build_file.file_ref

  file_ref = build_file.file_ref
  display_name = file_ref.display_name || file_ref.path || "Unknown"

  files_by_basename[display_name] << {
    build_file: build_file,
    file_ref: file_ref,
    display_name: display_name,
    path: file_ref.real_path.to_s
  }
end

# Find duplicates
duplicates = files_by_basename.select { |_, files| files.length > 1 }

if duplicates.empty?
  puts "✅ No duplicates found!"
else
  puts "❌ Found #{duplicates.length} duplicate file basenames:\n\n"

  duplicates.each do |basename, files|
    puts "📄 #{basename} (#{files.length} instances):"
    files.each_with_index do |file, idx|
      puts "  #{idx + 1}. #{file[:path]}"
    end
    puts ""
  end
end

puts "=" * 80
puts "Total files: #{build_files.length}"
puts "Unique basenames: #{files_by_basename.length}"
puts "Duplicate basenames: #{duplicates.length}"
