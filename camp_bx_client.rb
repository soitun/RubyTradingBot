require_relative 'generic_client'
require 'json'

class CampBXClient < GenericClient

  def initialize(key, secret)
    @key = key
    @secret = secret
    @base_url = 'http://CampBX.com/api/'
  end

end