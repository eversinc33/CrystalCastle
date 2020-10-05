require_relative 'LoggedException'

class InvalidConfigException < LoggedException
  def initialize(msg)
    msg = "config.yml is invalid: #{msg}"
    super(msg)
  end
end
