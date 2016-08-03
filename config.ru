require './main.rb'

use Rack::Session::Cookie, :key => 'rack.session',
  :expire_after => 2592000,
  :secret => nil

run Sinatra::Application