#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'FLEXR.xcodeproj'
project = Xcodeproj::Project.open(project_path)

flexr_target = project.targets.find { |t| t.name == 'FLEXR' }

puts "➕ Adding Supabase package dependency to FLEXR target..."

# Find the Supabase package reference
supabase_package = project.root_object.package_references.find do |pkg|
  pkg.requirement.to_s.include?('supabase-swift') || pkg.repositoryURL.include?('supabase-swift')
end

if supabase_package
  puts "   Found Supabase package: #{supabase_package.repositoryURL}"

  # Create package product dependency
  supabase_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  supabase_product.product_name = 'Supabase'
  supabase_product.package = supabase_package

  # Add to target's package dependencies
  flexr_target.package_product_dependencies << supabase_product

  puts "   ✅ Added Supabase product dependency to FLEXR target"
else
  puts "   ❌ Supabase package reference not found"
end

project.save
puts "💾 Project saved"
