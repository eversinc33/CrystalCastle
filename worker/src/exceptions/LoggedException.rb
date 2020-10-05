class LoggedException < StandardError
  def initialize(msg)
    Logger.log_warning_to_file("Exception occured: #{msg}")
    super(msg)
  end
end
