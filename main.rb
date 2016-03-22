require 'sinatra'
require 'sinatra/json'
require './bd_uses.rb'
require 'haml'

get '/' do
  @cahes = Cashe.all.order(:name)
  haml :index
end

get '/cards/:cashe/:barcode' do
  # card balanse
  @response = {}
  @response[:cashe_percent]=Cashe.select(:percent).where(:id=>params[:cashe])
  @card_value = Cards.left_join(:bonuses, :card_id=>:id).where(:barcode=>params[:barcode]).select_group(:card_percent).select_append{sum(:value).as(total)}
  @response[:card_percent]=@card_value[:card_percent]
  @response[:bonuses]=@card_value[:total]
end

post '/cards/:barcode/:sum_out/:sum_in' do
  
end