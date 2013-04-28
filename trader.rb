require_relative 'camp_bx_client'
require_relative 'mt_gox_client'
require 'psych'

class Trader

  def initialize
    @client = nil
    @avgs = Hash.new()
    @avgs['bid'] = 0
    @avgs['ask'] = 0
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

    puts 'Wallet: ' + @client.wallets.to_s
    puts 'Ticker: ' + @client.ticker.to_s
  end

  def run
    @client.get_prices()
    @client.get_orders()
    update_averages()

    rand = rand(10) + 1
    #Begin Drafting a trade
    btcAvailable = btcAvailable/rand
    price = calc_price('ask')

    best_price = (@client.ticker['ask'] > @client.ticker['bid'])?@client.ticker['ask']:@client.ticker['bid']

    puts best_price

  end

  def update_averages
    total_bid = 0
    total_ask = 0
    num_ask = 0
    num_bid = 0

    @client.trades.each do |trade|
      if trade['trade_type'] == 'bid'
        total_bid += trade['price'].to_f
        num_bid += 1
      else
        total_ask += trade['price'].to_f
        num_ask += 1
      end
    end

    @avgs['bid'] = total_bid/num_bid
    @avgs['ask'] = total_ask/num_ask

  end

  def calc_price(type)
    avg = @avgs[(type=='bid')?'ask':'bid']
    return avg
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
  #thread_exit = false
  #trade_thread = Thread.new {
  #  while true do
  #    if thread_exit == true
  #      Thread.current.exit()
  #    end
  #    trader.run()
  #    sleep 10
  #  end
  #}
  #input = ''
  #while input != 'exit'
  #  input = gets().chomp()
  #end
  #thread_exit = true
  #trade_thread.join



  #File.open('Tradetest.txt', 'w') { |file|
  #  @client.trades.each do |trade|
  #    file.write(trade.to_s+"\n")
  #  end
  #}

end


