# -*- encoding : utf-8 -*-
require 'test_helper'

class WatchdogTest < ActiveSupport::TestCase

  test "check_comments_created" do
    assert_not_equal "", Watchdog.check_comments_created
  end

  test "check_load ok" do
    Watchdog.expects(:retrieve_top_output).returns([0, 0, 0])
    assert_nil Watchdog.check_load
  end

  test "check_load high" do
    Watchdog.expects(:retrieve_top_output).returns([10, 10, 10])
    assert_not_equal "", Watchdog.check_load
  end

  test "check_pageviews" do
    assert_not_equal "", Watchdog.check_pageviews
  end

  test "run_hourly_alerts" do
    Watchdog.expects(:check_comments_created).returns("no nuevos comentarios")
    Watchdog.expects(:check_load).returns("carga elevada")
    Watchdog.expects(:check_pageviews).returns("no hay nuevas impresiones")

    assert_difference("NotificationEmail.count") do
      Watchdog.run_hourly_checks
    end
  end
end
