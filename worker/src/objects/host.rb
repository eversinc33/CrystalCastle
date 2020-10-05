class Host
  def initialize(ip, hostname, os)
    String @ip = ip
    if !hostname.nil?
      String @hostname = hostname
    else
      String @hostname = ip
    end
    String @os = os
    Array @services = []
  end

  attr_reader :ip
  attr_reader :hostname
  attr_reader :os
  attr_reader :services
end
