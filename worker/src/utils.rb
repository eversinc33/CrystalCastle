require_relative 'exceptions/CommandTimedOutException'
require_relative 'exceptions/InvalidConfigException'
require 'yaml'

##
# Run a command with a timeout to avoid hanging
# Params:
# - command_string: command line string to be executed by the system
# - timeout: timeout in seconds (default 120)
def execute_cmd_with_timeout(command_string, timeout = 120)
  result = nil
  begin
    result = `timeout #{timeout}s #{command_string}`
  rescue StandardError => e
    Logger.log_warning_to_file(e.message)
    raise e
  end
  # timeout if command was not succesful
  raise CommandTimedOutException.new command_string, timeout unless $?.success?

  # TODO: change this implementation to one that can differentiate betweend timeout and regular failure
  result
end

def parse_xml(file)
  begin
    xml = File.open file
  rescue StandardError => e
    Logger.log_warning_to_file(e.message)
  end
  REXML::Document.new(xml)
end

##
# Yield an ip for each host in the supplied subnet
# Params:
# - subnet: subnet string in the format of A.B.C.D/E
def generate_ips_from_subnet(subnet)
  range = IPAddr.new(subnet).to_range
  range.each_with_index do |ip, index|
    # do not use the network and broadcast address
    yield ip unless index.eql?(0) || index.eql?(range.to_a.length - 1)
  end
rescue IPAddr::InvalidAddressError
  raise InvalidConfigException "The subnet #{subnet} does not follow the format of A.B.C.D/E"
end

##
# Adds ips and subnets as targets to config.yml, replacing the old ones
# Params
# - ips_to_add: the ips or subnets to add as an array with ips in the format of A.B.C.D[/E]
def set_ip_config(ips_to_add)
  config = YAML.load_file(CONFIG_FILE)
  config.except!('targets')
  config['targets'] = []

  ips_to_add.each do |ip|
    if ip.to_s.include? '/'
      # subnet
      generate_ips_from_subnet(ip) do |i|
        begin
          config['targets'].append i.to_s
        rescue InvalidConfigException
          return false
        end
      end
    else
      begin
        # single ip
        i = IPAddr.new(ip)
        config['targets'].append i.to_s
      rescue IPAddr::InvalidAddressError
        return false
      end
    end
    begin
      File.open(CONFIG_FILE, 'w') { |f| YAML.dump(config, f) }
    rescue StandardError
      return false
    end
    true
  end
end
