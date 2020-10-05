require 'json'
require 'net/http'

class WebScanner
  def scan_hosts(hosts)
    hosts.each do |host|
      host.services.each do |service|
        next unless service.service.eql?('http') || service.service.eql?('htttps')

        # execute ffuf and fuzz for directories and files
        fuzz_urls host, service
        # scan_with_nikto host, http_port # disable for now, nikto takes too long
      end
    end
  end

  def fuzz_urls(host, http_port)
    Logger.log format('Fuzzing directories for %s:%i', host.ip, http_port.port)
    begin
      if http_port.service.eql? 'https'
        execute_cmd_with_timeout "ffuf -u https://#{host.ip}:#{http_port.port}/FUZZ -mc 200,204,302,307,401,403 -w #{WORDLIST} -o #{OUTPUT_DIRECTORY}/ffuf.json", 600 # no 301
      else
        execute_cmd_with_timeout "ffuf -u http://#{host.ip}:#{http_port.port}/FUZZ -mc 200,204,302,307,401,403 -w #{WORDLIST} -o #{OUTPUT_DIRECTORY}/ffuf.json", 600
      end
    rescue CommandTimedOutException
      # ffuf took longer than 10 minutes
    end

    pages = []
    status = []
    file = open('/app/worker/output/ffuf.json')&.read
    json = JSON.parse(file)
    json['results'].each do |result|
      found_page = result['input']['FUZZ']
      unless pages.include?(found_page) || found_page.empty?
        pages.append result['input']['FUZZ']
        status.append result['status']
      end
    end

    # if robots.txt was found, parse
    if pages.include? 'robots.txt'
      uri = if http_port.service.eql? 'https'
              URI("https://#{host.ip}:#{http_port.port}/robots.txt")
            else
              URI("http://#{host.ip}:#{http_port.port}/robots.txt")
            end
      robots = Net::HTTP.get uri

      robots.each_line do |line|
        next unless line.start_with?('Allow:') || line.start_with?('Disallow:')

        url = line.split(':')[1].strip
        next if pages.include? url

        # probe page if new
        response = Net::HTTP.get_response URI("http://#{host.ip}:#{http_port.port}/#{url}")
        unless response.code.to_s == '404'
          pages.append url
          status.append response.code
        end
      end
    end

    $db.add_pages host, http_port.port, pages, status, (http_port.service.eql? 'https')
  end

  def scan_with_nikto(host, http_port)
    Logger.log format('Running nikto against %s:%i', host.ip, http_port.port)
    begin
      scan = execute_cmd_with_timeout "nikto -h #{host.ip}:#{http_port.port}", 500
      $db.add_scan 'Nikto', scan, host.ip, http_port.port
    rescue CommandTimedOutException
      # pass
    end
  end
end
