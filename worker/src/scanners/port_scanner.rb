require_relative '../objects/network_service'
require_relative '../objects/ldap_service'
require 'rexml/document'

class PortScanner
  ##
  # Start a thread for each target in target_ips and return an array of host-objects
  def get_host_info(target_ips)
    @scanned_hosts = []
    threads = []
    thread_number = 0

    # start a thread for each target
    target_ips.each do |target_ip|
      threads.append Thread.new {
        thread_number += 1
        filename = "scan_#{thread_number}.xml"

        Logger.log format("Scanning %s : #{filename}", target_ip)

        ##
        # pre-scan to find open ports
        begin
          execute_cmd_with_timeout "nmap -T4 -Pn -p #{$nmap_port_range} -oX #{filename} #{target_ip}", 600
          open_ports = []
          parse_xml(filename).elements.each("/nmaprun/host/ports/port[state/@state='open']") do |port|
            port_number = Integer(REXML::XPath.match(
              REXML::Document.new(port.to_s),
              '/port/@portid'
            )[0].to_s)
            open_ports.append port_number
          end
          `rm #{filename}`

          ##
          # scan enumerated ports (also scan 1 to have a closed port for better men
          # os detection)
          scan = if open_ports.length > 0
                   execute_cmd_with_timeout "nmap -p #{open_ports.join(',')},65535 -A -O -sC -sV -oX #{filename} #{target_ip}", 600
                 else
                   execute_cmd_with_timeout "nmap -p #{open_ports.join(',')}1,65535 -A -O -sC -sV -oX #{filename} #{target_ip}", 600
                 end
          scan_results = parse_xml filename
          `rm #{filename}`

          # basic info
          hostname = REXML::XPath.match(scan_results, '/nmaprun/host/hostnames/hostname/@name')[0].to_s
          os = REXML::XPath.match(scan_results, '/nmaprun/host/os/osmatch/osclass/@osfamily')[0].to_s # TODO: exact flavour
          hostname = target_ip if hostname.eql? ''
          $db.add_host hostname, target_ip, os
          host_to_add = Host.new(
            target_ip,
            hostname,
            os
          )

          $db.add_scan 'nmap', scan, target_ip
          analyze_ports scan_results, host_to_add

          ##
          # add to scanned hosts
          @scanned_hosts.unshift host_to_add
        rescue CommandTimedOutException => e
          puts e.message
        end
      }
    end

    threads.each(&:join)
    $db.log_event 'Finished nmap scan for all targets'
    @scanned_hosts
  end

  ##
  # Analyze nmap scan results to add the open ports as services to the host object
  def analyze_ports(scan_results, host)
    scan_results.elements.each("/nmaprun/host/ports/port[state/@state='open']") do |port|
      # get service name
      service_name = REXML::XPath.match(
        REXML::Document.new(port.to_s),
        "/port[state/@state='open']/service/@name"
      )[0].to_s

      # get port number
      port_number = Integer(REXML::XPath.match(
        REXML::Document.new(port.to_s),
        '/port/@portid'
      )[0].to_s)

      # check services
      if service_name.eql?('http') || service_name.eql?('http-proxy')
        if (port_number == 5985) && host.os.include?('Windows')
          # then this is most likely not http but winrm
          host.services.append NetworkService.new(host.ip, port_number, 'WinRM')
          unless host.os.eql?('Windows') || host.os.eql?('Linux')
            # this is probably windows but was not recognized due to filtered ports
            host.os = 'Windows'
          end
        end
        host.services.append NetworkService.new(host.ip, port_number, 'http')
      elsif service_name.eql? 'https'
        host.services.append NetworkService.new(host.ip, port_number, 'https')
      elsif service_name.eql? 'ftp'
        host.services.append NetworkService.new(host.ip, port_number, 'ftp')
      elsif service_name.eql? 'ldap'
        # get domain name
        extra_info = REXML::XPath.match(
          REXML::Document.new(port.to_s),
          "/port[state/@state='open']/service/@extrainfo"
        )[0].to_s
        begin
          domain_name = extra_info.split('Domain: ').last.split(',').first
          host.services.append LdapService.new(host.ip, port_number, 'ldap', domain_name)
        rescue StandardError
          # domain could not be parsed
          host.services.append LdapService.new(host.ip, port_number, 'ldap')
        end
      elsif service_name.eql?('microsoft-ds') || service_name.eql?('netbios-ssn')
        host.services.append NetworkService.new(host.ip, port_number, 'smb')
      else
        # not for a scanner
        host.services.append NetworkService.new(host.ip, port_number, service_name)
      end
    end
  end
end
