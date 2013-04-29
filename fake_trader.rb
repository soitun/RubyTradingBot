require_relative 'camp_bx_client'
require_relative 'mt_gox_client'
require_relative 'trader'
require 'psych'

class FakeTrader < Trader

  def initialize
    super()
    @wallets = Hash.new()
    @wallets['usd'] = 20
    @wallets['bitcoin'] = 0.15
    puts @wallets
  end

  def start_up
    @client.get_prices()
    puts @client.ticker
    if !load_state()
      puts 'using defaults'
      @last_price['buy'] = @client.ticker['bid']
      @last_price['sell'] = @client.ticker['ask']
    end
    save_state()
    @last_total = @total_wealth
  end

  def run
    min_btc = 0.02
    min_usd = 3
    @client.get_prices()

    rand = rand(3) + 2
    #Begin Drafting a Sell
    btcAvailable = @wallets['bitcoin']
    btcAvailable = btcAvailable/rand

    price = (@client.ticker['ask'] > @client.ticker['bid'])?@client.ticker['ask']:@client.ticker['bid']
    puts 'Price = '+price.to_s+'. Buy price(plus 0.7%) = '+(@last_price['buy']*1.007).to_s

    if(btcAvailable > min_btc && price > (@last_price['buy']*1.007))
      do_trade('sell',btcAvailable,price)
      puts 'Executing sell of '+'%.8f' % btcAvailable+' for $'+price.to_s+'. Total of '+'%.2f'%(price*btcAvailable)
      @last_price['sell'] = price
      @loop_count = 0
      save_state()
    end


    rand = rand(10) + 1
    #Begin Drafting a Buy
    usdAvailable = @wallets['usd']
    usdAvailable = usdAvailable/rand

    price = (@client.ticker['ask'] < @client.ticker['bid'])?@client.ticker['ask']:@client.ticker['bid']

    #usdAvailable > min_usd &&
    puts 'Price = '+price.to_s+'. Sell price(minus 0.7%) = '+(@last_price['sell']-(0.007*@last_price['sell'])).to_s
    if(usdAvailable > min_usd && price < (@last_price['sell']-(0.007*@last_price['sell'])))
      amount = usdAvailable/price
      do_trade('buy',amount,price)
      puts 'Executing buy of '+'%.8f'%amount+' for $'+'%.2f'%price+'. Total of '+'%.2f'%(price*amount)
      @last_price['buy'] = price
      @loop_count = 0
      save_state()
    end

    if @loop_count == 240
      @loop_count = 0
      @last_price['buy'] = @client.ticker['bid']
      @last_price['sell'] = @client.ticker['ask']
      puts 'Not enough trading. Resetting prices'
    end
    @loop_count += 1
    print_gains()
    puts @loop_count
    STDOUT.flush
  end

  def print_gains
    puts 'Current wallet has: '+(@wallets['usd']).to_s+' USD and '+'%.8f'%(@wallets['bitcoin'])+' BTC'
    puts 'That is an increase in total wealth of '+'%.5f' %(total_value()-@last_total).to_s
  end

  def total_value
    float_amt = @wallets['bitcoin']
    float_price = @client.ticker['ask']
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
  end

end

if __FILE__ == $0
  trader = FakeTrader.new()
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