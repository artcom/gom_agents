module AsyncHelpers
  
  def eventually options = {}
    timeout = options[:timeout] || 2
    interval = options[:interval] || 0.1
    time_limit = Time.now + timeout
    loop do
      begin
        yield
      # rubocop:disable HandleExceptions
      rescue => error
      # rubocop:enable HandleExceptions
      end
      return if error.nil?
      raise error if Time.now >= time_limit
      sleep interval
    end
  end
  
end
