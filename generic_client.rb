require 'net/http'
require 'uri'

class GenericClient

  attr_reader :wallets,:ticker,:orders

  def initialize
    @wallets = Hash.new()
    @wallets['usd'] = 0
    @wallets['bitcoin'] = 0
    @wallets['fee'] = 0.55

    @ticker = Hash.new()
    @ticker['bid'] = 0
    @ticker['ask'] = 0

    @orders = nil
  end

  def send_data(uri, headers, data)

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.read_timeout = 240

      if data == nil
        req = Net::HTTP::Get.new(uri.request_uri)
      else
        req = Net::HTTP::Post.new(uri.request_uri)
        req.set_form_data(data)
      end

      req['User-Agent'] = 'Mozilla/5.0 (compatible; Ruby Trading Platform)'
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