require_relative 'camp_bx_client'
require_relative 'mt_gox_client'
require 'psych'

class Trader

  def initialize
    @client = nil
    read_settings()
  end

  def read_settings
    settings = Psych.load_file('config.yaml')
    case settings['client']
      when 'mtgox' then
        @client = MtGoxClient.new(settings['key'],settings['secret'])
      when 'campbx' then
        @client = CampBXClient.new(settings['user'],settings['pass'])
      else
        abort('Bad settings file. Please delete and do the setup')
    end

    puts 'Read settings.'

  end

  def start_up
    #TODO: Check for backup and if there, restore state
    @client.start_up
    @client.get_orders
  end

  def run

  end

end

if __FILE__ == $0

  if !File.exist? 'config.yaml'
    puts "First Run Detected\nPlease answer the following setup questions."
    puts "\nWhich Bitcoin exchange do you use?\n1. Mt. Gox\n2. CampBX"
    settings = Hash.new
    choice = gets.chomp
    if choice == '1'
      settings['client'] = 'mtgox'
      puts 'Please enter your API key: '
      settings['key'] = gets.chomp
      puts 'Please enter your Secret key: '
      settings['secret'] = gets.chomp
    elsif choice == '2'
      settings['client'] = 'campbx'
      puts 'Please enter your username: '
      settings['user'] = gets.chomp
      puts 'Please enter your password: '
      settings['pass'] = gets.chomp
    else
      abort 'Invalid choice. Please rerun program.'
    end

    File.open('config.yaml','w') do |file|
      file.puts settings.to_yaml
    end

    puts 'Config complete. Now starting'
  end

  trader = Trader.new()
  trader.start_up()
  #trade_thread = Thread.new {
  #  trader.run()
  #  sleep 10
  #}

  #trade_thread.join

end


