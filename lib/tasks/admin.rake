namespace :admin do
  desc 'grant admin privileges to a user'
  task :grant, [:uid] => :environment do |_, args|
    change_admin_rights(args[:uid], true)
  end

  desc 'revoke admin privileges of a user'
  task :revoke, [:uid] => :environment do |_, args|
    change_admin_rights(args[:uid], false)
  end

  desc 'list the admin users'
  task list: :environment do
    puts User.where(admin: true).pluck(:uniqueid)
  end
end

def change_admin_rights(uid, rights)
  u = User.find_by(uniqueid: uid)
  if u
    puts(u.update(admin: rights) ? 'User updated' : 'An error occurred while trying to update the user')
  else
    puts "Can't find a user with uniqueid #{ uid }"
  end
end