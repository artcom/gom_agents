require 'fileutils'

def setup_celluloid_logger(output, level)
  puts ' * Setting up Celluloid Logger: '.yellow
  case output
  when 'file'
    puts '   * output: FILE'.yellow
    logfile = File.expand_path('../../../log/test.log', __FILE__)
    FileUtils.mkdir_p(File.dirname(logfile))
    logfile = File.open(logfile, 'a')
    logfile.sync = true
    Celluloid.logger = Logger.new(logfile)
  when 'stdout'
    puts '   * Celluloid Logger output: STDOUT'.yellow
  else
    fail "unknown output for celluloid logger: #{output}"
  end

  case level
  when 'info', 'warn', 'error', 'debug'
    puts "   * level: #{level}".yellow
    Celluloid.logger.level = Logger.const_get(level.upcase)
  else
    fail "unknown loglevel for celluloid logger: #{level}"
  end
end
