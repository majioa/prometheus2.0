namespace :platform5 do
desc "Import all ACL for packages from Platform5 to database"
task :acls => :environment do
  require 'open-uri'

  puts "import acls"
  puts Time.now

  Acl.update_from_gitalt "ALT Linux", "Platform5"

  puts Time.now
end
end
