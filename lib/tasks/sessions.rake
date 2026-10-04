namespace :sessions do
  desc "Delete sessions that have been idle beyond Session::IDLE_TIMEOUT"
  task purge_expired: :environment do
    puts "Purged #{Session.purge_expired!} idle session(s)."
  end
end
