require 'net/ping'

class PingScanner
  def initialize
    @ips_up = []
    @ips_down = []
  end

  attr_reader :ips_up

  ##
  # start a thread for each ip in targets
  def check_up(targets)
    threads = []
    targets.each do |target_ip|
      threads.append Thread.new { ping_host target_ip.to_s }
    end
    threads.each(&:join)
    @ips_up
  end

  def ping_host(target_ip)
    ping = system("ping -c 1 #{target_ip}")
    if ping.eql? true # if 0 exit code
      Logger.log format('Host is up: %s', target_ip)
      @ips_up.unshift target_ip
    else
      Logger.log format('Host is down: %s', target_ip)
      $db.add_host(target_ip, target_ip, 'Offline')
      @ips_down.unshift target_ip
    end
  end
end
