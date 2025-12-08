require 'xcodeproj'

project = Xcodeproj::Project.open('FLEXR.xcodeproj')
puts "Available targets:"
project.targets.each { |t| puts "  - #{t.name}" }
