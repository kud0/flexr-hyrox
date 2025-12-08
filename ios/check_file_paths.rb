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

puts "🔍 Checking file paths in Compile Sources..."

# Get sources phase
sources_phase = flexr_target.source_build_phase

# Check specific problematic files
problem_files = [
  'WatchConnectivityService.swift',
  'AppleSignInService.swift',
  'PlanService.swift',
  'CoreDataManager.swift',
  'OnboardingView.swift'
]

problem_files.each do |filename|
  puts "\n📄 #{filename}:"

  sources_phase.files.each do |build_file|
    next unless build_file.file_ref

    if build_file.file_ref.display_name == filename || build_file.file_ref.path&.include?(filename)
      real_path = build_file.file_ref.real_path.to_s
      puts "  Path: #{real_path}"
      puts "  Exists: #{File.exist?(real_path)}"
    end
  end
end
