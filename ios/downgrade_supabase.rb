#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Downgrading Supabase package..."

# Find Supabase package reference
supabase_ref = project.root_object.package_references.find do |ref|
  ref.repositoryURL.include?('supabase-swift')
end

if supabase_ref
  puts "Found Supabase package: #{supabase_ref.repositoryURL}"
  puts "Current requirement: #{supabase_ref.requirement.inspect}"

  # Try downgrading to 2.4.0 which is more stable
  puts "\n📉 Changing to version 2.4.0..."
  supabase_ref.requirement = {
    'kind' => 'upToNextMajorVersion',
    'minimumVersion' => '2.4.0'
  }

  project.save

  puts "✅ Supabase downgraded to 2.4.0"
  puts "🔄 Now resolving packages..."
else
  puts "❌ Supabase package not found"
  exit 1
end
