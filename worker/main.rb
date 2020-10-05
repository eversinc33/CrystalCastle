require 'pg'
require 'yaml'
require_relative 'src/database/db'
require_relative 'src/crystal_castle'
require_relative 'src/utils'
require_relative 'src/constants'

puts ''
puts ' ▄▄· ▄▄▄   ▄· ▄▌.▄▄ · ▄▄▄▄▄ ▄▄▄· ▄▄▌   ▄▄·  ▄▄▄· .▄▄ · ▄▄▄▄▄▄▄▌  ▄▄▄ .'
puts '▐█ ▌▪▀▄ █·▐█▪██▌▐█ ▀. •██  ▐█ ▀█ ██•  ▐█ ▌▪▐█ ▀█ ▐█ ▀. •██  ██•  ▀▄.▀·'
puts '██ ▄▄▐▀▀▄ ▐█▌▐█▪▄▀▀▀█▄ ▐█.▪▄█▀▀█ ██▪  ██ ▄▄▄█▀▀█ ▄▀▀▀█▄ ▐█.▪██▪  ▐▀▀▪▄'
puts '▐███▌▐█•█▌ ▐█▀·.▐█▄▪▐█ ▐█▌·▐█ ▪▐▌▐█▌▐▌▐███▌▐█ ▪▐▌▐█▄▪▐█ ▐█▌·▐█▌▐▌▐█▄▄▌'
puts '·▀▀▀ .▀  ▀  ▀ •  ▀▀▀▀  ▀▀▀  ▀  ▀ .▀▀▀ ·▀▀▀  ▀  ▀  ▀▀▀▀  ▀▀▀ .▀▀▀  ▀▀▀ '
puts "Version: #{CC_VERSION}"
puts '>> https://github.com/fumamatar/crystalcastle'
puts ''

def print_help
  puts 'options:'
  puts '--setup-db : setup database tables'
  puts '--reset-db : delete all entries from database'
end

def main
  reset_db = false
  setup_db = false
  ARGV.each do |a|
    reset_db = true if a.eql? '--reset-db'
    setup_db = true if a.eql? '--setup-db'
    if a.eql?('-h') || a.eql?('--help')
      print_help
      return
    end
  end

  $db = Database.new reset_db, setup_db
  unless reset_db || setup_db
    `mkdir -p #{LOG_DIRECTORY}`
    `mkdir -p #{OUTPUT_DIRECTORY}`

    # parse config
    config = YAML.load_file(CONFIG_FILE)
    $nmap_port_range = config['nmap_port_range']

    # parse targets
    hosts_to_scan = []
    config['targets'].each do |target|
      if target.to_s.include? '/'
        generate_ips_from_subnet(target.to_s) do |ip|
          hosts_to_scan.append ip
        end
      else
        hosts_to_scan.append target.to_s
      end
    end

    # run
    begin
      Logger.log_to_file "!! Starting scan at #{Time.new.inspect}"
      $db.log_event('scan started')
      `touch /tmp/crystalcastle.lock`
      cc = CrystalCastle.new hosts_to_scan
      cc.run
      Logger.log_to_file "!! Finished scan at #{Time.new.inspect}"
      $db.log_event('scan finished')
      `rm /tmp/crystalcastle.lock`
    rescue StandardError => e
      puts e.backtrace
      Logger.log_warning_to_file e.message
      `rm /tmp/crystalcastle.lock`
    end
  end
end

main
