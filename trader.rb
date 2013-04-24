require 'yaml/dbm'
require_relative 'mt_gox_client'
require_relative 'camp_bx_client'

class Trader

  def initialize
    @client = nil
  end

  def restore_backup

  end

end

if __FILE__ == $0

  if !File.exist? 'config.yaml'
    puts "Config File Missing\nPlease make sure the config file is in the proper directory"
    abort('No config file found')
  end

  trader = Trader.new()
  trader.restore_backup

end


