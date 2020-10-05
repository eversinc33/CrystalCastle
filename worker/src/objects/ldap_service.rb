class LdapService < NetworkService
  def initialize(ip, port, service, domain_name = nil)
    @domain_name = domain_name
    super ip, port, service
  end

  # TODO: save ad domain etc
  # def save_to_db
  #  $db.add_port(@ip, @port, @service)
  # end

  attr_accessor :domain_name
end
