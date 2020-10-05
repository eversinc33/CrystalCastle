class Logger
  def self.log(message)
    puts format('[+] %s', message)
  end

  def self.log_warning_to_file(message)
    puts format('[!] %s', message)
    `echo '[#{Time.now}]--> #{message}' >> #{LOG_FILE}`
  end

  def self.log_to_file(message)
    puts format('[+] %s', message)
    `echo '[#{Time.now}]--> #{message}' >> #{LOG_FILE}`
  end
end
