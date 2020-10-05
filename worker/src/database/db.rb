require 'bcrypt'
require 'base64'
require_relative '../constants'

class Database
  def initialize(reset = false, setup_tables = false)
    # Drop
    if reset
      Logger.log 'Resetting databases. Run --setup-tables afterwards'
      execute_command 'DROP TABLE IF EXISTS Users CASCADE'
      execute_command 'DROP TABLE IF EXISTS Targets CASCADE'
      execute_command 'DROP TABLE IF EXISTS Pages CASCADE'
      execute_command 'DROP TABLE IF EXISTS Vulnerabilities CASCADE'
      execute_command 'DROP TABLE IF EXISTS Ports CASCADE'
      execute_command 'DROP TABLE IF EXISTS Scans CASCADE'
      execute_command 'DROP TABLE IF EXISTS RecentActivity CASCADE'
    end
    if setup_tables
      Logger.log 'Creating tables if they are not existing.'
      create_tables
      if execute_command('SELECT * FROM Users').to_a.empty?
        Logger.log 'Registering default user.'
        register_user CC_USER, CC_PASS
      end
    end
  end

  def execute_command(cmd)
    con = PG.connect dbname: DBNAME, user: DBUSER, host: DBHOST, password: DBPASS
    result = con.exec cmd
    result
  rescue PG::Error => e
    puts e.message
  ensure
    con&.close
  end

  def create_tables
    execute_command "CREATE TABLE IF NOT EXISTS Users(
          Name TEXT PRIMARY KEY,
          Password TEXT)"

    execute_command "CREATE TABLE IF NOT EXISTS Targets(
        Ip VARCHAR(16) PRIMARY KEY,
        Hostname VARCHAR(20),
        Os VARCHAR(20))"

    execute_command "CREATE TABLE IF NOT EXISTS Pages(
        Id SERIAL PRIMARY KEY,
        Ip VARCHAR(16),
        Port SMALLINT,
        Page VARCHAR(150),
        Status SMALLINT,
        Https BOOLEAN)"

    execute_command "CREATE TABLE IF NOT EXISTS Vulnerabilities(
        Id SERIAL PRIMARY KEY,
        Ip VARCHAR(16),
        Port SMALLINT,
        Service VARCHAR(20),
        Type VARCHAR(40),
        Vulnerable BOOLEAN)"

    execute_command "CREATE TABLE IF NOT EXISTS Ports(
        Id SERIAL PRIMARY KEY,
        Ip VARCHAR(16),
        Port SMALLINT,
        Service VARCHAR(20))"

    execute_command "CREATE TABLE IF NOT EXISTS Scans(
        Id SERIAL PRIMARY KEY,
        Port SMALLINT,
        Ip VARCHAR(16),
        Type VARCHAR(20),
        Output TEXT)"

    execute_command "CREATE TABLE IF NOT EXISTS RecentActivity(
        Id SERIAL PRIMARY KEY,
        Message TEXT,
        Time TIMESTAMP)"
  end

  def log_event(msg)
    execute_command "INSERT INTO
          RecentActivity (
              Message,
              Time)
          VALUES (
              '#{msg}',
              NOW()::timestamp
          )"
  end

  def register_user(username, password)
    hash = BCrypt::Password.create(password)

    execute_command "INSERT INTO
          Users (
              Name,
              Password)
          VALUES (
              '#{username}',
              '#{hash}'
          ) ON CONFLICT DO NOTHING"
  end

  def login_user?(username, password)
    hash = execute_command("SELECT password FROM Users WHERE Name = '#{username}'")
    unless hash.to_a.empty?
      return true if BCrypt::Password.new(hash[0]['password']) == password
    end
    false
  end

  def add_host(hostname, ip, os)
    Logger.log(format('Saving host %s to db', hostname))

    # delete old
    execute_command "DELETE FROM Targets WHERE Ip = '#{ip}' and Hostname = '#{hostname}'"

    execute_command "INSERT INTO
          Targets (
              Ip,
              Hostname,
              Os)
          VALUES (
              '#{ip}',
              '#{hostname}',
              '#{os}'
          ) ON CONFLICT DO NOTHING"
  end

  def remove_host(ip)
    execute_command "DELETE FROM Targets WHERE Ip = '#{ip}'"
    execute_command "DELETE FROM Pages WHERE Ip = '#{ip}'"
    execute_command "DELETE FROM Ports WHERE Ip = '#{ip}'"
    execute_command "DELETE FROM Vulnerabilities WHERE Ip = '#{ip}'"
    execute_command "DELETE FROM Scans WHERE Ip = '#{ip}'"
  end

  def add_pages(host, http_port, pages, status, is_https = false)
    pages_it = pages.each
    status_it = status.each

    # delete old
    execute_command "DELETE FROM Pages WHERE Ip = '#{host.ip}' and Port = '#{http_port}'"

    loop do
      execute_command "INSERT INTO
            Pages (
                Ip,
                Port,
                Page,
                Status,
                Https)
            VALUES (
                '#{host.ip}',
                '#{http_port}',
                '#{pages_it.next}',
                '#{status_it.next}',
                '#{is_https}'
            )"
    end
  end

  def add_port(target_ip, port_number, service_name)
    # delete old
    execute_command "DELETE FROM Ports WHERE Ip = '#{target_ip}' and Port = '#{port_number}' and Service = '#{service_name}'"

    execute_command "INSERT INTO
      Ports (
          Ip,
          Port,
          Service)
      VALUES (
          '#{target_ip}',
          '#{port_number}',
          '#{service_name}'
      )"
  end

  def register_ftp_vulnerability(host, ftp_port, vulnerable)
    $db.log_event(format('%s is vulnerable to anonymous ftp login on port %i!', host.hostname, ftp_port))

    execute_command "INSERT INTO
            Vulnerabilities (
                Ip,
                Port,
                Service,
                Type,
                Vulnerable)
            VALUES (
                '#{host.ip}',
                '#{ftp_port}',
                'ftp',
                'Anonymous login',
                '#{vulnerable}'
            )"
  end

  def register_smb_vulnerability(host, smb_port, vulnerable)
    $db.log_event(format('%s is vulnerable to anonymous smb login on port %i!', host, smb_port))

    execute_command "INSERT INTO
            Vulnerabilities (
                Ip,
                Port,
                Service,
                Type,
                Vulnerable)
            VALUES (
                '#{host.ip}',
                '#{smb_port}',
                'smb',
                'Anonymous login',
                '#{vulnerable}'
            )"
  end

  def add_scan(type, scan, target_ip, port = 0)
    # delete old
    execute_command "DELETE FROM Scans WHERE Ip = '#{target_ip}' and Port = '#{port}' and Type = '#{type}'"

    execute_command "INSERT INTO
            Scans (
                Ip,
                Port,
                Type,
                Output)
            VALUES (
                '#{target_ip}',
                '#{port}',
                '#{type}',
                '#{Base64.strict_encode64(scan)}'
            )"
  end
end
