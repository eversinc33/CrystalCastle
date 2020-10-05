require 'net/ftp'

class LdapScanner
  def scan_hosts(hosts)
    hosts.each do |host|
      host.services.each do |service|
        next unless service.service.eql? 'ldap'

        begin
          if service.domain_name.nil?
            service.domain_name = get_domain host
            service.domain_name = host.hostname
          end
          output = execute_cmd_with_timeout "ad-ldap-enum -l #{host.ip} -d #{service.domain_name}"
          $db.add_scan 'ad-ldap-enum', output, host.ip, service.port
          # TODO: parse file
        rescue CommandTimedOutException
          # pass
        end
      end
    end
  end

  def get_domain(host)
    ldap_enum = execute_cmd_with_timeout "crackmapexec ldap #{host.ip}"
    ldap_enum.split('(domain:').last.split(')').first
  rescue CommandTimedOutException
    raise CommandTimedOutException
  end
end
