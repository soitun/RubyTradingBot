require_relative 'camp_bx_client'
require_relative 'mt_gox_client'
require 'xmpp4r-simple'
require 'psych'


class Trader

  def initialize
    @client = nil
    @last_price = Hash.new()
    @last_price['buy'] = 0
    @last_price['sell'] = 0
    @total_wealth = 0
    @useim = false
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

    if(settings['useim'] == 'true')
      @useim = true
      puts 'connecting...'
      @im = Jabber::Simple.new(settings['imuser'],settings['impass'])
      puts 'Connected!'
      @alertee = settings['imalertee'].to_s
    else
      puts 'Not using IM'
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
      return false
    end

    data = Psych.load_file('backup.yaml')

    @last_price['buy'] = data['last_prices']['buy'].to_f
    @last_price['sell'] = data['last_prices']['sell'].to_f

    @total_wealth = data['total_wealth']

    return true
  end

  def start_up
    @client.start_up

    if !load_state()
      puts 'using defaults'
      @last_price['buy'] = @client.ticker['bid']
      @last_price['sell'] = @client.ticker['ask']
    end
    save_state()
    puts 'Wallet: ' + @client.wallets.to_s
    puts 'Ticker: ' + @client.ticker.to_s
    puts 'Total Value: $' + '%.8f' % total_value.to_s
  end

  def run
    @client.get_prices()
    @client.update_wallet_info()
    @client.get_orders()

    puts 'Trades: '+@client.orders.to_s

    hasbuy = false
    hassell = false

    @client.orders.each { |x|
      if(x['type']=='ask')
        hassell = true
      end
      if(x['type']=='bid')
        hasbuy = true
      end
    }
    puts 'Sell: '+hassell.to_s+' Buy: '+hasbuy.to_s

    percent_changed_ask = (@client.ticker['bid']-@last_price['buy'])/@last_price['buy']
    percent_changed_bid = (@client.ticker['ask']-@last_price['sell'])/@last_price['sell']

    #Begin Drafting a Sell
    amount = 0.05*percent_changed_ask
    price = @client.ticker['bid']

    amount = 0 if @client.wallets['bitcoin'] < amount

    #amount > min_btc &&
    puts @client.ticker
    puts 'Price = '+price.to_s+'. Buy price(plus 1%) = '+(@last_price['buy']*1.01).to_s
    if(amount>0.05 && !hassell)
      @client.do_trade('ask',amount,price)
      puts 'Executing sell of '+'%.8f' % amount+'for $'+price.to_s
      @im.deliver(@alertee, 'Executing sell of '+'%.8f' % amount+'for $'+price.to_s) if @useim
      @last_price['sell'] = price
      save_state()
    end

    #Begin Drafting a Buy
    amount = 0.05*percent_changed_bid
    price = @client.ticker['ask']

    amount = 0 if @client.wallets['usd']<amount*price

    puts 'Price = '+price.to_s+'. Sell price(minus 1%) = '+(@last_price['sell']-(0.01*@last_price['sell'])).to_s
    if(amount>0.05 && !hasbuy)
      @client.do_trade('bid',amount,price)
      puts 'Executing buy of '+'%.8f' % amount+'for $'+price.to_s
      @im.deliver(@alertee, 'Executing buy of '+'%.8f' % amount+'for $'+price.to_s) if @useim
      @last_price['buy'] = price
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
    float_amt = @client.wallets['bitcoin']
    float_price = @client.ticker['ask']
    @total_wealth = @client.wallets['usd']+(float_amt*float_price)
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

    puts 'Do you want to be alerted over XMPP? (y/n):'
    choice = gets.chomp.downcase
    if choice == 'y'
      settings['useim'] = 'true'
      puts 'Input username of bot:'
      settings['imuser'] = gets.chomp
      puts 'Input password for bot:'
      settings['impass'] = gets.chomp
      puts 'Lasly, input user to be alerted:'
      settings['imalertee'] = gets.chomp
    else
      settings['useim'] = 'false'
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
      sleep 45
    end
  }
  input = ''
  while input != 'exit'
    input = gets().chomp()
  end
  thread_exit = true
  trade_thread.join

end


