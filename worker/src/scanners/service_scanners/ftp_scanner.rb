require 'net/ftp'

class FtpScanner
  def scan_hosts(hosts)
    hosts.each do |host|
      host.services.each do |service|
        try_anonymous_login(host, service) if service.service.eql? 'ftp'
      end
    end
  end

  def try_anonymous_login(host, service)
    ftp = Net::FTP.new
    ftp.connect(host.ip, service.port)
    ftp.login('anonymous', 'anonymous@domain.com')
    # no exception : vulnerable
    Logger.log(format('%s is vulnerable to anonymous ftp login!', host.hostname))
    $db.register_ftp_vulnerability host, service.port, true
    true
  rescue SystemCallError
    Logger.log(format('%s is not vulnerable to anonymous ftp login', host.hostname))
    $db.register_ftp_vulnerability host, service.port, false
    false
  end
end
