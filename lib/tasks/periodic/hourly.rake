namespace :gm do
  desc "Hourly operations"
  task :hourly => :environment do
    Watchdog.run_hourly_checks
    GmSys.kill_workers
    AbTest.delay.update_ab_tests
    Competitions.delay.update_user_competitions_indicators
    NotificationEmail.check_system_emails
    UsersNewsfeed.delay.process
    Cache.hourly_clear_file_caches
  end
end
