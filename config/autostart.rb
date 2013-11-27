module Gom
  module Agents
    def self.autostart
      Celluloid.logger.warn "Gom::Agents - Using default autostart setup. No additional actors will be started"
      # override this in your application to start your own agents
    end
  end
end
