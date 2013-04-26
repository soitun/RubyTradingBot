require_relative 'generic_client'
require 'json'

class CampBXClient < GenericClient

  def initialize(user, pass)
    super()
    @user = user
    @pass = pass
    @base_url = 'http://CampBX.com/api/'
  end

  def start_up

  end

  def get_prices

  end

  def update_wallet_info

  end

  def get_orders

  end

end