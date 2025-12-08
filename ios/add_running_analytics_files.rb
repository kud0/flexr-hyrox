#!/usr/bin/env ruby
# Script to add new Running Analytics files to Xcode project

require 'securerandom'

project_file = 'FLEXR.xcodeproj/project.pbxproj'
content = File.read(project_file)

# Files to add with their file references
files_to_add = [
  { name: 'AllRunsListView.swift', path: 'FLEXR/Sources/Features/Analytics/Running/AllRunsListView.swift' },
  { name: 'EnhancedRunCard.swift', path: 'FLEXR/Sources/Features/Analytics/Running/EnhancedRunCard.swift' },
  { name: 'RunningSessionFilterSheet.swift', path: 'FLEXR/Sources/Features/Analytics/Running/RunningSessionFilterSheet.swift' }
]

# Generate unique IDs for each file (using format similar to existing ones)
def generate_id
  SecureRandom.hex(12).upcase
end

# Find where to insert in PBXBuildFile section
build_file_section_end = content.index('/* End PBXBuildFile section */')

# Find where to insert in PBXFileReference section
file_ref_section_end = content.index('/* End PBXFileReference section */')

# Find the Running group in the project
running_group_match = content.match(/(\w+)\s*\/\*\s*Running\s*\*\/\s*=\s*\{[^}]*isa\s*=\s*PBXGroup[^}]*children\s*=\s*\([^)]*\)/)

unless running_group_match
  puts "Could not find Running group in project"
  exit 1
end

# Find the FLEXR target's sources build phase
sources_phase_match = content.match(/(\w+)\s*\/\*\s*Sources\s*\*\/\s*=\s*\{[^}]*isa\s*=\s*PBXSourcesBuildPhase[^}]*files\s*=\s*\([^)]*\)/)

insertions = []
files_to_add.each do |file|
  file_ref_id = generate_id
  build_file_id = generate_id

  # Check if file already exists
  if content.include?(file[:name])
    puts "#{file[:name]} already in project, skipping..."
    next
  end

  insertions << {
    name: file[:name],
    path: file[:path],
    file_ref_id: file_ref_id,
    build_file_id: build_file_id
  }
end

if insertions.empty?
  puts "No files to add"
  exit 0
end

# Add PBXBuildFile entries
build_file_entries = insertions.map do |f|
  "\t\t#{f[:build_file_id]} /* #{f[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{f[:file_ref_id]} /* #{f[:name]} */; };"
end.join("\n")

content = content.sub('/* End PBXBuildFile section */', "#{build_file_entries}\n/* End PBXBuildFile section */")

# Add PBXFileReference entries
file_ref_entries = insertions.map do |f|
  "\t\t#{f[:file_ref_id]} /* #{f[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{f[:name]}; sourceTree = \"<group>\"; };"
end.join("\n")

content = content.sub('/* End PBXFileReference section */', "#{file_ref_entries}\n/* End PBXFileReference section */")

# Add to Running group children
running_children_match = content.match(/(Running\s*\*\/\s*=\s*\{[^}]*children\s*=\s*\()([^)]*)\)/)
if running_children_match
  existing_children = running_children_match[2]
  new_children_entries = insertions.map { |f| "\n\t\t\t\t#{f[:file_ref_id]} /* #{f[:name]} */," }.join("")
  new_children = existing_children.rstrip + new_children_entries + "\n\t\t\t"
  content = content.sub(/(Running\s*\*\/\s*=\s*\{[^}]*children\s*=\s*\()([^)]*)\)/, "\\1#{new_children})")
end

# Add to Sources build phase - need to find FLEXR target's sources phase
# Look for the FLEXR target sources build phase specifically
flexr_sources_match = content.match(/\/\* Sources \*\/\s*=\s*\{[^}]*isa\s*=\s*PBXSourcesBuildPhase;[^}]*buildActionMask[^}]*files\s*=\s*\(([^)]*)\)/m)
if flexr_sources_match
  existing_files = flexr_sources_match[1]
  new_file_entries = insertions.map { |f| "\n\t\t\t\t#{f[:build_file_id]} /* #{f[:name]} in Sources */," }.join("")
  new_files = existing_files.rstrip + new_file_entries + "\n\t\t\t"

  # Replace only the first occurrence (FLEXR target)
  content = content.sub(/(\/\* Sources \*\/\s*=\s*\{[^}]*isa\s*=\s*PBXSourcesBuildPhase;[^}]*buildActionMask[^}]*files\s*=\s*\()([^)]*)\)/) do |match|
    "#{$1}#{new_files})"
  end
end

File.write(project_file, content)
puts "Added #{insertions.length} files to project:"
insertions.each { |f| puts "  - #{f[:name]}" }
