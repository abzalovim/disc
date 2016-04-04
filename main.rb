require 'sinatra'
require 'sinatra/json'
require './bd_uses.rb'
require 'haml'
# require "sinatra/reloader" if development?

get '/' do
  @cashes = Cashe.order(:name).all
  haml :index
end

get '/cards/:cashe/:barcode/:pin', :provides => [:json, :xml] do
  # card balanse
  DB[:cashes].insert(:id=>params[:cashe], :name=>"Касса №#{params[:cashe]}") if Cashe[params[:cashe]].nil?
  DB[:cards].insert_conflict.insert(:barcode=>params[:barcode]) if Card[{:barcode=>params[:barcode]}].nil?
  @resp = {}
  @resp[:cashe_percent]=DB[:cashes].where(:id=>params[:cashe]).get(:cashe_percent)
  @resp[:card_percent]=DB[:cards].where(:barcode=>params[:barcode]).get(:card_percent)
  @card_value = DB[:cards].where(:barcode=>params[:barcode]).left_join(:bonuses, :card_id=>:id).sum(:value)
  @resp[:bonuses] = @card_value.nil? ? 0 : @card_value
  respond_to do |f|
    f.json{ json @resp, :layout => nil }
    f.xml{ XmlSimple.xml_out(@resp, {:keeproot => true, :noescape => true}) }
  end
end

get '/cards/:cashe/:check_id/:barcode/:payment/:sum_out/:sum_in' do
  card_id = DB[:cards].where(:barcode=>params[:barcode]).get(:id)
  str_sum = params[:sum_out]
  value = 0-str_sum.to_f
  Bonus.create({:card_id => card_id, :cashe_id => params[:cashe], :check_id => params[:check_id], :value => value}) unless value==0

  sum_in = params[:sum_in]
  value = sum_in.to_f
  Bonus.create({:card_id => card_id, :cashe_id => params[:cashe], :check_id => params[:check_id], :value => value}) unless value==0

  payment = params[:payment]
  value = payment.to_f
  
  Payment.create({:card_id => card_id, :cashe_id => params[:cashe], :check_id => params[:check_id], :value => value})
  haml :null, :layout => nil
end
