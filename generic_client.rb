require 'net/http'

class GenericClient

  def initialize
  end

  def send_data(uri, headers, data)

    if data == nil
      req = Net::HTTP::Get.new(uri)
    else
      req = Net::HTTP::Post.new(uri)
      req.set_form_data(data)
    end

    headers.each do |key, value|
      req[key] = value
    end

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        return res
      else
        puts res.value
        return nil
    end

  end

end