require 'xcodeproj'
project = Xcodeproj::Project.open('FLEXR.xcodeproj')
target = project.targets.find { |t| t.name.include?('Watch') && t.product_type.include?('watch') }
# Likely 'FLEXRWatch Watch App' or just 'FLEXRWatch' depending on structure.
# Let's match strictly or list them.
targets = project.targets.select { |t| t.name.include?('Watch') }

targets.each do |t|
  puts "Target: #{t.name}"
  file = t.source_build_phase.files.find { |f| f.file_ref && (f.file_ref.name == 'RouteData.swift' || f.file_ref.path.include?('RouteData.swift')) }
  if file
    puts "  ✅ Included: #{file.file_ref.path}"
  else
    puts "  ❌ Not included"
  end
end
