require_relative 'generic_client'
require 'openssl'
require 'base64'
require 'json'

class MtGoxClient < GenericClient

  def initialize(key, secret)
    super()
    @key = key
    @secret = secret
    @base_url = 'http://data.mtgox.com/api/1/'
  end

  def start_up
    update_wallet_info()
  end

  def get_prices
    uri = URI(@base_url+'BTCUSD/ticker')
    header = Hash.new()
    ticker =  JSON.parse(send_data(uri,header,nil))
    puts ticker['return']
  end

  def update_wallet_info
    uri = URI(@base_url+'generic/private/info')
    data = Hash.new()
    data['nonce'] = Time.now.to_f*1000
    data_string = build_query_string(data)
    sign = do_encrypt(data_string)
    sign.gsub!("\n",'')
    header = Hash.new()
    header['User-Agent'] = 'Ruby Bot'
    header['Rest-Key'] = @key
    header['Rest-Sign'] = sign
    wallet = JSON.parse(send_data(uri,header,data))
    @wallets['usd'] = wallet['return']['Wallets']['USD']['Balance']['value']
    @wallets['bitcoin'] = wallet['return']['Wallets']['BTC']['Balance']['value']
    puts @wallets
  end

  def get_orders

  end

  def do_encrypt(data_string)
    temp =  OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha512'),  Base64.decode64(@secret) , data_string)
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