require_relative 'camp_bx_client'
require_relative 'mt_gox_client'
require_relative 'trader'
require 'psych'
require 'json'

class FakeTrader < Trader

  def initialize(usd, bitcoin)
    super()
    @wallets = Hash.new()
    @wallets['usd'] = usd
    @wallets['bitcoin'] = bitcoin
    puts @wallets
    @ticker = Hash.new()
  end

  def start_up
    if !load_state()
      puts 'using defaults'
      @last_price['buy'] = prices['bid']
      @last_price['sell'] = prices['ask']
    end
    save_state()
    @last_total = @wallets['usd']+(@wallets['bitcoin']*prices['ask'])
    puts 'Starting wealth is: $'+'%.4f'%@last_total
    puts "\n"
  end

  def run(prices=nil)
    @client.get_prices()
    if prices == nil
      @client.get_prices()
      prices = @client.ticker
    end
    puts Time.now().to_s
    min_btc = 0.01
    min_usd = 2
    @client.get_prices()

    rand = rand(5) + 1.25
    #Begin Drafting a Sell
    btcAvailable = @wallets['bitcoin']
    btcAvailable = (btcAvailable/rand).round(8)

    price = (prices['ask'] > prices['bid'])?prices['ask']:prices['bid']
    puts 'Price = '+price.to_s+'. Buy price(plus 1%) = '+(@last_price['buy']*1.01).to_s

    if(btcAvailable > min_btc && price > (@last_price['buy']*1.01))
      do_trade('sell',btcAvailable,price)
      puts 'Executing sell of '+'%.8f' % btcAvailable+' for $'+price.to_s+'. Total of '+'%.2f'%(price*btcAvailable)
      @last_price['sell'] = price
      @loop_count = 0
      save_state()
    end


    rand = rand(5) + 1.25
    #Begin Drafting a Buy
    usdAvailable = @wallets['usd']
    usdAvailable = (usdAvailable/rand).round(5)

    price = (prices['ask'] < prices['bid'])?prices['ask']:prices['bid']

    #usdAvailable > min_usd &&
    puts 'Price = '+price.to_s+'. Sell price(minus 1%) = '+(@last_price['sell']-(0.01*@last_price['sell'])).to_s
    if(usdAvailable > min_usd && price < (@last_price['sell']-(0.01*@last_price['sell'])))
      amount = (usdAvailable/price).round(8)
      do_trade('buy',amount,price)
      puts 'Executing buy of '+'%.8f'%amount+' for $'+'%.2f'%price+'. Total of '+'%.2f'%(price*amount)
      @last_price['buy'] = price
      @loop_count = 0
      save_state()
    end

    if @loop_count == 960
      @loop_count = 0
      @last_price['buy'] = prices['bid']
      @last_price['sell'] = prices['ask']
      puts 'Not enough trading. Resetting prices'
    end
    @loop_count += 1
    print_gains()
    puts @loop_count.to_s+"\n\n"
    STDOUT.flush
  end

  def print_gains
    puts 'Current wallet has: '+(@wallets['usd']).to_s+' USD and '+'%.8f'%(@wallets['bitcoin'])+' BTC'
    puts 'That is an increase in total wealth of '+'%.5f' %(total_value()-@last_total).to_s
  end

  def total_value
    float_amt = @wallets['bitcoin']
    float_price = prices['ask']
    @total_wealth = @wallets['usd']+(float_amt*float_price)
    return @total_wealth
  end

  def do_trade(type,amount,price)
    if type == 'sell'
      @wallets['usd'] += amount*price
      @wallets['bitcoin'] -= amount
    else
      @wallets['bitcoin'] += amount
      @wallets['usd'] -= price*amount
    end
    @wallets['bitcoin'].round(8)
    @wallets['usd'].round(5)
  end

  def loop
    if File.exist? 'prices.txt'
      file = File.new('prices.txt', 'r')
      while (line = file.gets)
        prices = Hash.new()
        json = JSON.parse(line)
        prices['bid'] = json['buy']['value'].to_f
        prices['ask'] = json['sell']['value'].to_f
        run(prices)
      end
      file.close
    else
      puts 'No log data. Exiting.'
    end
  end

end

if __FILE__ == $0
  puts 'How much USD in account: '
  usd = gets.chomp
  puts 'How many bitcoins in account: '
  btc = gets.chomp
  puts '1 - Fake Data. 2 - Live'
  choice = gets.chomp

  if choice.to_i == 1
    trader = FakeTrader.new(usd.to_f, btc.to_f)
    trader.start_up()
    trader.loop
    abort('Ran out of logs ending')
  end

  trader = FakeTrader.new(usd.to_f, btc.to_f)
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