module EnttecGomDaemon

  module GnpDmxAdapter
    def GnpDmxAdapter.on_gnp gnp
      case gnp[:uri]
      when %r|#{@values_path}:(.*)$|
        on_channel_gnp gnp 
      when %r|#{@values_path}$|
        on_universe_gnp gnp
      else
        []
      end
    end

    def GnpDmxAdapter.on_universe_gnp gnp
      # debug "UNIVERSE #{gnp.inspect}"
      updates = []
      if gnp.key?(:initial)
        gnp[:initial][:node][:entries].each do |entry|
          if entry.key?(:attribute)
            updates << {:channel => entry[:attribute][:name], :value => entry[:attribute][:value]}
          end
        end
      end
      updates
    end

    def GnpDmxAdapter.on_channel_gnp gnp
      # debug "CHANNEL #{gnp.inspect}"
      updates = []
      if gnp.key?(:update) && gnp[:update].key?(:attribute) 
        attribute = gnp[:update][:attribute]
        updates << { :channel => attribute[:name], :value => attribute[:value]}
      elsif gnp.key?(:create) && gnp[:create].key?(:attribute) 
        attribute = gnp[:create][:attribute]
        updates << { :channel => attribute[:name], :value => attribute[:value]}
      elsif gnp.key?(:delete) && gnp[:delete].key?(:attribute) 
        attribute = gnp[:delete][:attribute]
        updates << { :channel => attribute[:name], :value => "0"}
      else
        warn "unsupported gnp '#{gnp.inspect}'"
      end
      updates
    end
  end
end
