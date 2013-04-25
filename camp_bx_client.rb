require_relative 'generic_client'
require 'json'

class CampBXClient < GenericClient

  def initialize(user, pass)
    @user = user
    @pass = pass
    @base_url = 'http://CampBX.com/api/'
  end

end