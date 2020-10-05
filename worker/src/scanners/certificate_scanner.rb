class CertificateScanner
  def scan_hosts(hosts)
    hosts.each do |host|
      host.services.each do |service|
        if service.service.eql? 'https'
          # parse subdomains from ASM in certificate if there is https
          try_get_subdomains host.ip, service.port
        end
      end
    end
  end

  def try_get_subdomains(host, https_port)
    subdomains = execute_cmd_with_timeout format('python3 scripts/enum_subdomain_from_asm.py %s %s', host, https_port)
    puts subdomains # TODO: use these and save to db
  rescue CommandTimedOutException
    # pass
  end
end
