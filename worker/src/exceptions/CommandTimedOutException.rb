require_relative 'LoggedException'

class CommandTimedOutException < LoggedException
  def initialize(command_string, timeout)
    msg = "Timeout while calling '#{command_string}' after #{timeout}s"
    super(msg)
  end
end
