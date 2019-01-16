require 'json'
require 'net/ping'
require 'resolv'

class NetworkMonitor
  INTERNET_HOSTS     = %w(8.8.8.8 1.1.1.1 9.9.9.9)
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
    raise unless smarthome_cli_available?
  end

  def internet_up?
    return true if internet_ip_pingable? && dns_resolves?

    # uh oh! internet is down.

    # Is the router even reacheable?
    if !router_ip_pingable?
      puts "[#{Time.now}] Router #{@router_ip} is not reacheable. Rebooting..."
      reboot_router(:router)
      post_reboot_sleep
    end

    return true if internet_ip_pingable? && dns_resolves?

    # Internet is still down after checking connectivity to router
    # and perhaps even rebooting it. Let's try restarting the modem.
    puts "[#{Time.now}] Internet is not reacheable. Rebooting modem..."
    reboot_modem
    post_reboot_sleep(:modem)
    return true if internet_ip_pingable? && dns_resolves?

    # Internet is still not available after rebooting modem. Force
    # a router reboot one last time.
    puts "[#{Time.now}] Internet is not reacheable. Rebooting router..."
    reboot_router
    post_reboot_sleep(:router)

    # Let's check if the Internet is available one last time. If not, we simply give up.
    internet_ip_pingable? && dns_resolves?
  end

  private

  def post_reboot_sleep(item)
    puts "[#{Time.now}] Rebooted #{item}. Waiting for #{@post_reboot_delay} seconds..."
    sleep(@post_reboot_delay)
  end

  def reboot_router
    reboot_device(@router_plug_ip)
  end

  def reboot_modem
    reboot_device(@modem_plug_ip)
  end

  def reboot_device(device_ip)
    power_off(device_ip)
    sleep(POWER_ON_OFF_DELAY)
    power_on(device_ip)
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
    switch_power true, ip
  end

  def power_off(ip)
    switch_power false, ip
  end

  def switch_power(value, ip)
    puts "[#{Time.now}] Switching power #{value ? 'on' : 'off'} for #{ip}..."
    payload = { system: {
                set_relay_state: { state: value ? 1 : 0 }
              } }.to_json
    send_command payload, ip
  end

  def send_command(payload, ip)
    `tplink-smarthome-api sendCommand #{ip} '#{payload}'`
  end

  def host_up?(host)
    check = Net::Ping::External.new(host)
    check.ping?
  end

  def smarthome_cli_available?
    `which tplink-smarthome-api`
    return true if $? == 0

    puts "[#{Time.now}] tplink-smarthome-api could not be found."
    puts "[#{Time.now}] To install it, run: `npm install -g tplink-smarthome-api`"
    false
  end

  def produce_random_failures?
    @produce_random_failures
  end

  def out_of_luck?
    Random.rand(OOL_ODDS + 1) == 0
  end
end
