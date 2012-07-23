# -*- encoding : utf-8 -*-
module GmSys

  WORKER_PID_FILE = "#{Rails.root}/tmp/pids/delayed_worker.pid"
  TOO_MANY_JOBS = 1000

  class DjJobWrapper
    def initialize(task)
      @task = task
    end

    def perform
      eval(@task)
    end
  end

  def self.running?(pid)
    # Check if process is in existence
    # The simplest way to do this is to send signal '0'
    # (which is a single system call) that doesn't actually
    # send a signal
    begin
      Process.kill(0, pid)
      return true
    rescue Errno::ESRCH
      return false
    rescue ::Exception
      # for example on EPERM (process exists but does not belong to us)
      return true
    end
  end

  def self.kill_workers
    `#{Rails.root}/script/delayed_job stop`
  end

  def self.start_workers
    unless App.enable_bgjobs?
      Rails.logger.warn(
          "Background jobs functionality disabled, not starting DelayedJob.")
      return
    end

    `#{Rails.root}/script/delayed_job start`
  end

  # Ensures that there is a DelayedJob worker process running.
  def self.check_workers_pids
    return unless App.enable_bgjobs?

    is_running = false
    if File.exists?(WORKER_PID_FILE)
      pid = File.open(WORKER_PID_FILE).read
      is_running = self.running?(pid)
      if !is_running
        Rails.logger.warn(
            "DelayedJob pid file found but no process running. Cleaning up" +
            " and starting a new worker.")
        File.unlink(WORKER_PID_FILE)
      end
    end

    self.start_workers unless is_running
  end

  def self.job(task)
    # performs or schedules a lengthy job depending on the current configuration
    if App.enable_bgjobs?
      Delayed::Job.enqueue(DjJobWrapper.new(task))
    else
      Rails.logger.info("App.enable_bgjobs is disabled. Evaluating: #{task}")
      eval(task)
    end
  end


  def self.command(task, run_now=false)
    # performs or schedules a direct bash command
    if run_now || !App.enable_bgjobs?
      IO.popen(task) {|pipe| puts pipe.gets }
    else
      job("`#{task}`")
    end
  end

  def self.warn_if_big_queue
    pending_jobs = User.db_query(
        "SELECT COUNT(*) as count FROM delayed_jobs")[0]["count"].to_i
    if pending_jobs >= TOO_MANY_JOBS
      Notification.too_many_delayed_jobs(
          User.find(App.webmaster_user_id),
          :pending_jobs => pending_jobs).deliver
    end
  end
end
