require 'fileutils'

def redirect_celluloid_log
  logfile = File.expand_path('../../../log/test.log', __FILE__)
  FileUtils.mkdir_p(File.dirname(logfile))
  logfile = File.open(logfile, 'a')
  logfile.sync = true
  Celluloid.logger = Logger.new(logfile)
end
