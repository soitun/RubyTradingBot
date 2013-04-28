require_relative 'camp_bx_client'
require_relative 'mt_gox_client'
require 'psych'

class Trader

  def initialize
    @client = nil
    @last_price = Hash.new()
    @last_price['buy'] = 0
    @last_price['sell'] = 0
    @total_wealth = 0
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

    puts 'Settings loaded.'
  end

  def save_state
    data = Hash.new()
    data['last_prices'] = @last_price
    data['total_wealth'] = total_value
    File.open('backup.yaml','w') do |file|
      file.puts data.to_yaml
    end
  end

  def load_state
    if !File.exist? 'backup.yaml'
      puts 'No backup to load.'
    end

    data = Psych.load_file('backup.yaml')

    @last_price['ask'] = data['last_prices']['ask']
    @last_price['bid'] = data['last_prices']['bid']

    @total_wealth = data['total_wealth']
  end

  def start_up
    #TODO: Check for backup and if there, restore state
    load_state
    @client.start_up
    @last_price['buy'] = @client.ticker['bid']
    @last_price['sell'] = @client.ticker['ask']

    save_state()

    puts 'Wallet: ' + @client.wallets.to_s
    puts 'Ticker: ' + @client.ticker.to_s
    puts 'Total Value: $' + '%.8f' % total_value.to_s
  end

  def run
    min_btc = 1000000
    @client.get_prices()

    rand = rand(10) + 1
    #Begin Drafting a trade
    btcAvailable = @client.wallets['bitcoin']
    btcAvailable = btcAvailable/rand

    price = (@client.ticker['ask'] > @client.ticker['bid'])?@client.ticker['ask']:@client.ticker['bid']

    puts convert_int('price',price)
    puts '%.8f' % convert_int('amount',btcAvailable)
    #btcAvailable > min_btc &&
    if(price > (@last_price['buy']*1.15))
      #@client.do_trade('ask',btcAvailable,price)
      puts 'Executing trade of'+'%.8f' % convert_int('amount',btcAvailable)+'for $'+convert_int('price',price).to_s
      @last_price['ask'] = price
      save_state()
    end



  end

  def convert_int(type, quantity)
    if(type=='price')
      return quantity.to_f/1.0e5
    else
      return quantity.to_f/1.0e8
    end
  end

  def total_value
    float_amt = convert_int('amount',@client.wallets['bitcoin'])
    float_price = convert_int('price',@client.ticker['ask'])
    @total_wealth = convert_int('price',@client.wallets['usd'])+(float_amt*float_price)
    return @total_wealth
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
  thread_exit = false
  trade_thread = Thread.new {
    while true do
      if thread_exit == true
        Thread.current.exit()
      end
      trader.run()
      sleep 15
    end
  }
  input = ''
  while input != 'exit'
    input = gets().chomp()
  end
  thread_exit = true
  trade_thread.join

end


