class SmbScanner
  def scan_hosts(hosts)
    hosts.each do |host|
      host.services.each do |service|
        next unless service.service.eql? 'smb'

        scans = {
          'nmblookup' => "nmblookup -A #{host.ip}",
          'enum4linux' => "enum4linux -a -r -o -n -v #{host.ip}",
          'crackmapexec' => "crackmapexec smb #{host.ip}",
          'smbmap' => "smbmap -H #{host.ip}"
        }

        next unless try_anonymous_login? host, service

        scans.each do |key, value|
          begin
            result = execute_cmd_with_timeout value
            $db.add_scan key, result, host.ip, service.port
          rescue CommandTimedOutException
            # scan failed
          end
        end
      end
    end
  end

  def try_anonymous_login?(host, service)
    execute_cmd_with_timeout "echo ' ' | smbclient -L #{host.ip}", 30 # fail after 30s
    # no exception : vulnerable
    Logger.log(format('%s is vulnerable to anonymous smb login!', host.hostname))
    $db.register_smb_vulnerability host, service.port, true
    true
  rescue CommandTimedOutException
    Logger.log(format('%s is not vulnerable to anonymous smb login', host.hostname))
    $db.register_smb_vulnerability host, service.port, false
    false
  end
end
