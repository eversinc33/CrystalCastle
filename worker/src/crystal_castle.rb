require_relative 'logger'
require_relative 'objects/host'
require_relative 'scanners/port_scanner'
require_relative 'scanners/service_scanners/web_scanner'
require_relative 'scanners/service_scanners/ftp_scanner'
require_relative 'scanners/service_scanners/smb_scanner'
require_relative 'scanners/certificate_scanner'
require_relative 'scanners/ping_scanner'
require_relative 'scanners/service_scanners/ldap_scanner'
require_relative 'utils'

class CrystalCastle
  def initialize(targets)
    @targets = targets
    @ping_scanner = PingScanner.new
    @port_scanner = PortScanner.new
    @certificate_scanner = CertificateScanner.new
    @service_scanners = [
      LdapScanner.new,
      WebScanner.new,
      FtpScanner.new,
      SmbScanner.new
    ]
  end

  def run
    if check_hosts_up?
      scan_ports
      enumerate_subdomains
      scan_services
    else
      Logger.log 'All targets are offline. Check connectivity!'
    end
  end

  def check_hosts_up?
    @ips_up = @ping_scanner.check_up @targets
    return false if @ips_up.count.zero?

    true
  end

  def scan_ports
    @target_hosts = @port_scanner.get_host_info @ips_up
  end

  def enumerate_subdomains
    @certificate_scanner.scan_hosts @target_hosts
  end

  def scan_services
    @service_scanners.each do |scanner|
      begin
        scanner.scan_hosts @target_hosts
      rescue StandardError => e
        Logger.log_warning_to_file e.message
      end
    end
  end
end
