class NetworkService
  def initialize(ip, port, service)
    String @ip = ip
    Integer @port = port
    String @service = service
    save_to_db
  end

  def save_to_db
    $db.add_port(@ip, @port, @service)
  end

  attr_reader :ip
  attr_reader :port
  attr_reader :service
end
