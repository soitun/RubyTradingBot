require_relative 'generic_client'
require 'digest/hmac'
require 'json'

class MtGoxClient < GenericClient

  def initialize(user, pass)
    @user = user
    @pass = pass
    @base_url = 'http://data.mtgox.com/api/1/'
  end

end