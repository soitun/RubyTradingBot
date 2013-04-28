require_relative 'generic_client'
require 'openssl'
require 'base64'
require 'json'

class MtGoxClient < GenericClient

  def initialize(key, secret)
    super()
    @key = key
    @secret = secret
    @base_url = 'http://data.mtgox.com/api/2/'
  end

  def start_up
    update_wallet_info()
    get_prices()
  end

  def get_prices
    path = 'BTCUSD/money/ticker_fast'
    uri = URI(@base_url+path)
    header = Hash.new()
    ticker =  JSON.parse(send_data(uri,header,nil))
    if ticker['result'] != 'success'
      puts 'Could not get ticker data'
      return nil
    end
    @ticker['bid'] = ticker['data']['buy']['value']
    @ticker['ask'] = ticker['data']['sell']['value']
  end

  def update_wallet_info
    path = 'money/info'
    uri = URI(@base_url+path)
    data = Hash.new()
    data['nonce'] = Time.now.to_f*1000
    data_string = build_query_string(data)
    sign = do_encrypt(path, data_string)
    sign.gsub!("\n",'')
    header = Hash.new()
    header['Rest-Key'] = @key
    header['Rest-Sign'] = sign
    wallet = JSON.parse(send_data(uri,header,data))
    if wallet['result'] != 'success'
      puts 'Could not get wallet data'
      return nil
    end
    @wallets['usd'] = wallet['data']['Wallets']['USD']['Balance']['value']
    @wallets['bitcoin'] = wallet['data']['Wallets']['BTC']['Balance']['value']
    @wallets['fee'] = wallet['data']['Trade_Fee']
  end

  def get_orders
    path = 'BTCUSD/money/orders'
    uri = URI(@base_url+path)
    data = Hash.new()
    data['nonce'] = Time.now.to_f*1000
    data_string = build_query_string(data)
    sign = do_encrypt(path, data_string)
    sign.gsub!("\n",'')
    header = Hash.new()
    header['Rest-Key'] = @key
    header['Rest-Sign'] = sign
    trades = JSON.parse(send_data(uri,header,data))
    if trades['result'] != 'success'
      puts 'Could not get trade info data'
      return nil
    end
    @orders = trades['data']
  end

  def do_encrypt(path, data_string)
    temp =  OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha512'),  Base64.decode64(@secret) , path+0.chr+data_string)
    return Base64.encode64(temp)
  end

  def build_query_string(data)
    string_form = ''
    data.each do |key,value|
      if !string_form.empty?
        string_form += '&'
      end
      string_form += (URI::encode(key.to_s)+'='+URI::encode(value.to_s))
    end
    return string_form
  end

end

if __FILE__ == $0
  client = MtGoxClient.new('2b438eb5-9e57-4c12-a09a-4c6b5d78f67f','pcQDAJCqX6N10ecjVQrPP7sORL5st1RbYhmtPeQEHgnw14UdiHdq1DoLevG6JivrjEkvLzZX//9dYAgV17rvHQ==')
  #data = Hash.new()
  #data['nonce'] = Time.now.to_f*1000
  #data_string = client.build_query_string(data)
  #sign = client.do_encrypt(data_string)
  #sign.gsub!("\n",'')
  #puts sign
  puts client.wallets

end