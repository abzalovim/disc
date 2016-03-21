require 'rubygems'
require 'sinatra'
require 'sinatra/json'
#require './feed_fetcher.rb'
require 'haml'
require 'sequel'

get '/' do
  json :foo => 'bar'
end
