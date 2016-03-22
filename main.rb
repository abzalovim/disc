require 'sinatra'
require 'sinatra/json'
require './bd_uses.rb'
require 'haml'
require "sinatra/reloader" if development?

get '/' do
  @cashes = Cashe.order(:name).all
  haml :index
end

get '/cards/:cashe/:barcode' do
  # card balanse
  DB[:cashes].insert_ignore.insert(:id=>params[:cashe], :name=>"Касса №#{params[:cashe]}")
  DB[:cards].insert_ignore.insert(:barcode=>params[:barcode])
  @resp = {}
  @resp[:cashe_percent]=DB[:cashes].where(:id=>params[:cashe]).get(:cashe_percent)
  @resp[:card_percent]=DB[:cards].where(:barcode=>params[:barcode]).get(:card_percent)
  @card_value = DB[:cards].where(:barcode=>params[:barcode]).left_join(:bonuses, :card_id=>:id).sum(:value)
  @resp[:bonuses]= @card_value.nil? ? 0 : @card_value
  json @resp, :layout => nil
end

post '/cards/:cashe/:chec_id/:barcode/:sum_out/:sum_in' do
  
end