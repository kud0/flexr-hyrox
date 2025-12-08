#!/usr/bin/env ruby

# Script to add onboarding files to FLEXR Xcode project
# Run with: ruby add_onboarding_files.rb

require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the groups
flexr_group = project.main_group['FLEXR']
sources_group = flexr_group['Sources']
core_group = sources_group['Core']
models_group = core_group['Models']
features_group = sources_group['Features']
onboarding_group = features_group['Onboarding']

puts "📦 Adding files to FLEXR Xcode project..."

# Files to add (using relative paths from group location)
files_to_add = {
  models: [
    {
      name: 'OnboardingData.swift',
      path: 'OnboardingData.swift'
    }
  ],
  onboarding: [
    {
      name: 'OnboardingCoordinator.swift',
      path: 'OnboardingCoordinator.swift'
    },
    {
      name: 'OnboardingStep1_BasicProfile.swift',
      path: 'OnboardingStep1_BasicProfile.swift'
    },
    {
      name: 'OnboardingStep2_GoalRaceDetails.swift',
      path: 'OnboardingStep2_GoalRaceDetails.swift'
    },
    {
      name: 'OnboardingStep3_TrainingAvailability.swift',
      path: 'OnboardingStep3_TrainingAvailability.swift'
    },
    {
      name: 'OnboardingStep4_EquipmentAccess.swift',
      path: 'OnboardingStep4_EquipmentAccess.swift'
    },
    {
      name: 'OnboardingStep5_PerformanceNumbers.swift',
      path: 'OnboardingStep5_PerformanceNumbers.swift'
    },
    {
      name: 'OnboardingCompletionView.swift',
      path: 'OnboardingCompletionView.swift'
    }
  ]
}

# Remove existing references first (in case they're already there but incorrect)
puts "\n🧹 Cleaning up existing references..."
models_group.files.each do |file|
  if file.path == 'OnboardingData.swift'
    file.remove_from_project
    puts "  🗑️  Removed old reference: OnboardingData.swift"
  end
end

onboarding_group.files.each do |file|
  if file.path =~ /Onboarding(Coordinator|Step|Completion)/
    file.remove_from_project
    puts "  🗑️  Removed old reference: #{file.path}"
  end
end

# Add model files
puts "\n📄 Adding model files..."
files_to_add[:models].each do |file_info|
  file_name = file_info[:path]
  full_path = "FLEXR/Sources/Core/Models/#{file_name}"

  if File.exist?(full_path)
    file_ref = models_group.new_file(full_path)
    target.add_file_references([file_ref])
    puts "  ✅ Added #{file_info[:name]} to Models group"
  else
    puts "  ⚠️  File not found: #{full_path}"
  end
end

# Add onboarding view files
puts "\n📱 Adding onboarding view files..."
files_to_add[:onboarding].each do |file_info|
  file_name = file_info[:path]
  full_path = "FLEXR/Sources/Features/Onboarding/#{file_name}"

  if File.exist?(full_path)
    file_ref = onboarding_group.new_file(full_path)
    target.add_file_references([file_ref])
    puts "  ✅ Added #{file_info[:name]} to Onboarding group"
  else
    puts "  ⚠️  File not found: #{full_path}"
  end
end

# Save the project
puts "\n💾 Saving project..."
project.save

puts "\n✨ Done! All files have been added to the Xcode project."
puts "📝 Next steps:"
puts "  1. Open FLEXR.xcodeproj in Xcode"
puts "  2. Build the project (⌘+B)"
puts "  3. Fix any compilation errors if needed"
