require 'sinatra'
require 'pg'
require_relative 'worker/src/database/db'
require 'securerandom'

$db = Database.new

class CrystalCastleUI < Sinatra::Base
  enable :sessions
  set :session_secret, SecureRandom.hex(100)
  set :views, 'static'
  set :public_folder, File.dirname(__FILE__) + '/static'

  get '/login' do
    redirect '/' if session[:username]
    @failed = params[:failed]
    erb :login
  end

  get '/logout' do
    session.delete :username
    erb :login
  end

  get '/logs' do
    redirect '/' if session[:username].nil?
    @logs =  File.readlines LOG_FILE
    erb :logs
  end

  post '/go' do
    redirect '/login' if session[:username].nil?
    `touch /tmp/crystalcastle.lock`
    `sleep 1`
    cc_main_path = File.join(File.dirname(__FILE__), 'worker', 'main.rb')
    system("ruby #{cc_main_path} &")
    redirect '/'
  end

  post '/reset' do
    redirect '/login' if session[:username].nil?
    cc_main_path = File.join(File.dirname(__FILE__), 'worker', 'main.rb')
    system("ruby #{cc_main_path} --reset-db --setup-db")
    redirect '/'
  end

  post '/delete_host' do
    redirect '/login' if session[:username].nil?
    $db.remove_host params['ip']
    redirect '/'
  end

  post '/login' do
    username = params['username']
    password = params['password']
    if $db.login_user? username, password
      session[:username] = username
      redirect '/'
    else
      redirect '/login?failed=1'
    end
  end

  post '/adjust_config' do
    redirect '/login' if session[:username].nil?

    ips_to_add = params['ips_to_add']

    redirect '/config?error=1' unless set_ip_config ips_to_add
    redirect '/config'
  end

  get '/config' do
    redirect '/login' if session[:username].nil?
    @error = params['error'].to_i.eql? 1 ? true : false
    erb :config
  end

  get '/' do
    redirect '/login' if session[:username].nil?

    begin
      @scan_running = File.exist? '/tmp/crystalcastle.lock'
    rescue StandardError
      @scan_running = false
    end
    @hosts = $db.execute_command 'SELECT * FROM Targets'
    @services = {}
    @pages = {}
    @vulns = {}
    @scans = {}
    @recent_activity = $db.execute_command('SELECT * FROM RecentActivity').to_a.reverse

    unless @hosts.to_a.empty?
      @hosts.each do |host|
        # Get enumerated services
        @services[host['ip']] = $db.execute_command "SELECT * FROM Ports WHERE ip = '#{host['ip']}'"

        # Get enumerated web pages
        @pages[host['ip']] = $db.execute_command "SELECT * FROM Pages WHERE ip = '#{host['ip']}'"

        # Get vulnerabilities
        @vulns[host['ip']] = $db.execute_command "SELECT * FROM Vulnerabilities WHERE ip = '#{host['ip']}'"

        # Get scans
        @scans[host['ip']] = $db.execute_command "SELECT * FROM Scans WHERE ip = '#{host['ip']}'"
      end
    end

    erb :targets
  end
end
