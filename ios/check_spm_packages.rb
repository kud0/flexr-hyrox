#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "📦 SPM Packages in project:"
puts "=" * 60

# Get package references
project.root_object.package_references.each do |package_ref|
  puts "\nRepository URL: #{package_ref.repositoryURL}"

  # Get requirement (version, branch, etc.)
  requirement = package_ref.requirement
  puts "  Requirement: #{requirement.inspect}"
end

puts "\n" + "=" * 60

# Check targets and their package dependencies
project.targets.each do |target|
  next if target.package_product_dependencies.empty?

  puts "\nTarget: #{target.name}"
  puts "  Package Dependencies:"
  target.package_product_dependencies.each do |dep|
    puts "    - #{dep.product_name}"
  end
end
