require 'xcodeproj'
require 'plist'

project = Xcodeproj::Project.open('FLEXR.xcodeproj')

# Path to scheme management file
scheme_mgmt_path = 'FLEXR.xcodeproj/xcuserdata/alexsolecarretero.xcuserdatad/xcschemes/xcschememanagement.plist'

if File.exist?(scheme_mgmt_path)
  plist = Plist.parse_xml(scheme_mgmt_path)
  
  # Hide Supabase package schemes
  supabase_schemes = ['Functions', 'PostgREST', 'Realtime', 'Storage', 'Supabase']
  
  plist['SchemeUserState'] ||= {}
  
  supabase_schemes.each do |scheme|
    scheme_key = "#{scheme}.xcscheme_^#shared#^_"
    if plist['SchemeUserState'][scheme_key]
      # Mark as not visible
      plist['SchemeUserState'][scheme_key]['isShown'] = false
    end
  end
  
  # Write back
  File.write(scheme_mgmt_path, Plist::Emit.dump(plist))
  
  puts "✓ Hidden Supabase package schemes"
  puts "Only FLEXR and FLEXRWatch Watch App will show in scheme selector"
else
  puts "Scheme management file not found at expected location"
  puts "These schemes come from the Supabase package and are normal"
  puts "You can hide them manually in Xcode: Product > Scheme > Manage Schemes"
  puts "Then uncheck 'Show' for Functions, PostgREST, Realtime, Storage, Supabase"
end
