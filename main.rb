require 'sinatra'
require 'sinatra/json'
require './bd_uses.rb'
require 'haml'

get '/' do
  json :foo => 'bar'
end
