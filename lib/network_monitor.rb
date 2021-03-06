require 'json'
require 'net/ping'
require 'resolv'

class NetworkMonitor
  INTERNET_HOSTS     = %w(8.8.8.8 9.9.9.9 208.67.222.222)
  HOSTS_TO_RESOLVE   = %w(google.com amazon.com facebook.com)
  POWER_ON_OFF_DELAY = 5
  POST_REBOOT_DELAY  = 60 * 3
  OOL_ODDS           = 10 # 1 out of 10

  def initialize(router_ip:, router_plug_ip:, modem_plug_ip:, post_reboot_delay: POST_REBOOT_DELAY, produce_random_failures: false)
    @router_ip               = router_ip
    @router_plug_ip          = router_plug_ip
    @modem_plug_ip           = modem_plug_ip
    @produce_random_failures = produce_random_failures
    @post_reboot_delay       = post_reboot_delay

    unless python_dependency_met?
      puts "Python 2.7.x is required. Not found in PATH."
      exit 1
    end
  end

  def internet_up?
    return true if internet_ip_pingable? && dns_resolves?

    # uh oh! internet is down.

    # Is the router even reacheable?
    if !router_ip_pingable?
      puts "[#{Time.now}] Router #{@router_ip} is not reacheable. Rebooting..."
      $stdout.flush
      reboot_router
      post_reboot_sleep(:router)
    end

    return true if internet_ip_pingable? && dns_resolves?

    # Internet is still down after checking connectivity to router
    # and perhaps even rebooting it. Let's try restarting the modem.
    puts "[#{Time.now}] Internet is not reacheable. Rebooting modem..."
    $stdout.flush
    reboot_modem
    post_reboot_sleep(:modem)
    return true if internet_ip_pingable? && dns_resolves?

    # Internet is still not available after rebooting modem. Force
    # a router reboot one last time.
    puts "[#{Time.now}] Internet is not reacheable. Rebooting router..."
    $stdout.flush
    reboot_router
    post_reboot_sleep(:router)

    # Let's check if the Internet is available one last time. If not, we simply give up.
    internet_ip_pingable? && dns_resolves?
  end

  private

  def post_reboot_sleep(item)
    puts "[#{Time.now}] Rebooted #{item}. Waiting for #{@post_reboot_delay} seconds..."
    $stdout.flush
    sleep(@post_reboot_delay)
  end

  def reboot_router
    reboot_device(@router_plug_ip)
  end

  def reboot_modem
    reboot_device(@modem_plug_ip)
  end

  def reboot_device(ip)
    smart_plug_cmd(ip, 'off')
    sleep(POWER_ON_OFF_DELAY)
    smart_plug_cmd(ip, 'on')
    true
  end

  def internet_ip_pingable?(retry_delay: 10, retries: 3)
    return false if produce_random_failures? && out_of_luck?
    retries     ||= 0
    retry_delay ||= 10
    attempts      = 0

    while attempts <= retries
      sleep(retry_delay) if attempts > 0

      INTERNET_HOSTS.each do |host|
        return true if host_up?(host)
      end

      attempts += 1
    end

    false
  end

  def router_ip_pingable?
    return false if produce_random_failures? && out_of_luck?

    host_up?(@router_ip)
  end

  def dns_resolves?(retry_delay: 10, retries: 3)
    return false if produce_random_failures? && out_of_luck?

    retries     ||= 0
    retry_delay ||= 10
    attempts      = 0

    while attempts <= retries
      sleep(retry_delay) if attempts > 0

      HOSTS_TO_RESOLVE.each do |host|
        return true if DnsCheck.new(host).a?
      end

      attempts += 1
    end

    false
  end

  def power_on(ip)
    smart_plug_cmd(ip, 'on')
  end

  def power_off(ip)
    smart_plug_cmd(ip, 'off')
  end

  def host_up?(host)
    Net::Ping::External.new(host, 7, 1).ping?
  end

  def produce_random_failures?
    @produce_random_failures
  end

  def out_of_luck?
    Random.rand(OOL_ODDS + 1) == 0
  end

  def smart_plug_cmd(ip, command)
    `#{python_path} #{smartplug_script_path} -t #{ip} -c #{command}`
  end

  def smartplug_script_path
    File.join(File.expand_path(File.dirname(__FILE__)), '..', 'bin', 'tplink_smartplug.py')
  end

  def python_path
    @python_path ||= `which python`.to_s.strip
  end

  def python_dependency_met?
    `#{python_path} --version 2>&1`.match?(/2\.7/)
  end
end
