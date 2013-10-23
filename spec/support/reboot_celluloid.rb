require 'fileutils'

def reboot_celluloid
  Celluloid.shutdown
  Celluloid.boot
  # Celluloid.start
  FileUtils.rm('/tmp/cell_sock') if File.exist?('/tmp/cell_sock')
end
