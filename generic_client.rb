require 'net/http'
require 'uri'

class GenericClient

  attr_reader :wallets

  def initialize
    @wallets = Hash.new()
    @wallets['usd'] = 0
    @wallets['bitcoin'] = 0
  end

  def send_data(uri, headers, data)

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|

      if data == nil
        req = Net::HTTP::Get.new(uri.request_uri)
      else
        req = Net::HTTP::Post.new(uri.request_uri)
        req.set_form_data(data)
      end

      headers.each do |key, value|
        req[key] = value
      end

      http.request(req)
    end

    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        return res.body
      else
        puts res.value
        return nil
    end

  end

end

if __FILE__ == $0
  client = GenericClient.new()
  uri = URI('http://data.mtgox.com/api/1/BTCUSD/ticker')
  header = Hash.new()
  data = client.send_data(uri,header,nil)
  puts data
end