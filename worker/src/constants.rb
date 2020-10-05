CC_VERSION = '0.1.0'.freeze
# CONSTANTS:
ROOT_DIR = File.join(File.dirname(__FILE__), '..', '..').freeze
LOG_DIRECTORY = File.join(ROOT_DIR, 'worker', 'logs').freeze
LOG_FILE = File.join(LOG_DIRECTORY, 'crystalcastle.log').freeze
OUTPUT_DIRECTORY = File.join(ROOT_DIR, 'worker', 'output').freeze
CONFIG_FILE = File.join(ROOT_DIR, 'worker', 'config.yml').freeze
WORDLIST = File.join(ROOT_DIR, 'worker', 'lists', 'bigger.txt').freeze
VARIABLE_FILE = File.join(ROOT_DIR, '.db.env').freeze
variable_file = File.open(VARIABLE_FILE)
variable_file.each do |line|
  line.chomp!
  var = line.split('=')
  if var[0].eql? 'POSTGRES_DB'
    DBNAME = var[1]
  elsif var[0].eql? 'POSTGRES_USER'
    DBUSER = var[1]
  elsif var[0].eql? 'POSTGRES_PASSWORD'
    DBPASS = var[1]
  elsif var[0].eql? 'DB_HOST'
    DBHOST = var[1]
  elsif var[0].eql? 'CC_USER'
    CC_USER = var[1]
  elsif var[0].eql? 'CC_PASS'
    CC_PASS = var[1]
  end
end
