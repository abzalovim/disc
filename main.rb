require 'sinatra'
require 'sinatra/json'
require './bd_uses.rb'
require 'haml'
require 'xmlsimple'
require 'sinatra/respond_with'
require "sinatra/reloader" if development?

enable :sessions

get '/' do
  @cashes = Cashe.order(:name).all
  haml :index
end

get '/start' do
  @cashes = Cashe.order(:name).all
  haml :start, :layout => nil
end

post '/start' do
  session['cashe_id']=params['user']
  session['user']=Cashe[session['cashe_id']].name
  redirect to('/')
end

get '/logout' do
  session['user']=''
  session['cashe_id']=nil
  redirect to('/')
end

get '/cards/:cashe/:barcode/:pin/:resp' do
  # card balanse
  DB[:cashes].insert(:id=>params[:cashe], :name=>"Касса №#{params[:cashe]}") if Cashe[params[:cashe]].nil?
  DB[:cards].insert_conflict.insert(:barcode=>params[:barcode]) if Card[{:barcode=>params[:barcode]}].nil?
  @resp = {}
  @resp["cashe_percent"]=DB[:cashes].where(:id=>params[:cashe]).get(:cashe_percent)
  @resp["card_percent"]=DB[:cards].where(:barcode=>params[:barcode]).get(:card_percent)
  @card_value = DB[:cards].where(:barcode=>params[:barcode]).left_join(:bonuses, :card_id=>:id).sum(:value)
  @resp["bonuses"] = @card_value.nil? ? 0 : @card_value
  st_resp = params[:resp]
  if st_resp == 'xml'
    r = '<?xml version="1.0" encoding="utf-8"?>'+"\n"
    r+=XmlSimple.xml_out({"id"=>"0", "keys"=>@resp}, {:keeproot => true, :noescape => true, 'AttrPrefix' => true })
    p r
  elsif st_resp == 'json'
    json @resp, :layout => nil
  else
    p 'Error in query'
  end
end

get '/cards/:cashe/:check_id/:barcode/:payment/:sum_out/:sum_in/:articles' do
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

  art = params[:articles]
  arr = art.split("%A4")
  arr.each do |ware|
    unless ware.empty?
      code, article, qnty, sumwd = ware.split("%B5")
      p "code:#{code} summ:#{sumwd}"
      Articles.create({:cashe_id => params[:cashe], :check_id => params[:check_id], :code => code, :article => article, :quantity => qnty, :sum => sumwd})
    end
  end
  haml :null, :layout => nil
end

get '/clients' do
  session['secret'] = ''
  haml :'clients/list'
end

post '/clients.ajax' do
  cart=params["cart"]
  unless cart.empty?
    return json DB[:clients].where(:id=>DB[:cards].where(:barcode=>cart).select(:client_id)).limit(20).all
  end
  filter=params["filter"]
  unless filter.empty?
    str=""
    filter.split(' ').each { |fl|
      if str==""
        str=Sequel.|(Sequel.ilike(:family,"%#{fl}%"),Sequel.ilike(:name,"%#{fl}%"),Sequel.ilike(:surname,"%#{fl}%"),Sequel.ilike(:mobile,"%#{fl}%"))
      else
        str=Sequel.&(str,Sequel.|(Sequel.ilike(:family,"%#{fl}%"),Sequel.ilike(:name,"%#{fl}%"),Sequel.ilike(:surname,"%#{fl}%"),Sequel.ilike(:mobile,"%#{fl}%")))
      end
    }
    return json DB[:clients].where(str).limit(20).all
  end
  json DB[:clients].limit(20).all
  #json { :domain => domain, :info => {:available => info.available?, :registered => info.registered?, :expires => info.expires_on} } unless info.nil?
end

get '/client/cart' do
  haml :'clients/cart'
end

post '/client/cart' do
  cart=params["cart"];
  cart.gsub!(' ','')
  if cart.empty?
    session['secret']='Нужно обязательно заполнить карту!'
    redirect to('/client/cart')
  end
  prefix=cart[0..4]
  if ['01500','15000'].include?(prefix) then
  else
    session['secret']='Регистрируем только новую карту!'
    redirect to('/client/cart')
  end
  cart='0'+cart if prefix=='15000'
  if cart.length!=13 then
    session['secret']='Ошибочный номер карты!'
    redirect to('/client/cart')
  end
  unless Card[{:barcode=>cart}].nil? then
    session['secret']="Карта #{cart} уже добавлена!"
    redirect to('/client/cart')
  end
  session['secret']=''
  session['cart']=cart
  redirect to("client/new")
end

get '/client/new' do
  @cart=session['cart']
  haml :'clients/new'
end

post '/client/new' do
  params.each{|key,value| puts "#{key} => #{value}"}
  fl_sms = (params['fl_sms']=='on')
  fl_pol = params['fl_pol']
  mobile = params['phone']
  if mobile.length<17
    mobile=''
  else
    mobile='7'+mobile[4..6]+mobile[9..11]+mobile[13..17]
  end
  puts "'#{mobile}'"
  puts session['user']

  DB.transaction do
    clnt = DB[:clients].insert({
                                   :family=>params['surname'],
                                   :name=>params['name'],
                                   :surname=>params['lastname'],
                                   :m_f=>fl_pol,
                                   :birthday=>params['birthday'],
                                   :get_sms=>fl_sms,
                                   :active=>true,
                                   :mobile=>mobile,
                                   :city=>params['city'],
                                   :comments=>session['user']
                               })
    crd = DB[:cards].insert({
                                :barcode => session['cart'],
                                :client_id => clnt
                            })
    if params['fl_bonuses'=='on'] then
      value = Float[params['bonuses']] rescue false
      Bonus.create({:card_id => crd, :cashe_id => session['cashe_id'], :value => value}) if value
    end
    raise Sequel::Rollback
  end
  redirect to('/clients')
end

get '/client/:id/edit' do
  Client[params[:id]].to_hash.to_s
end

get '/test' do
  haml :test
end

post '/ajax.json' do
  domain = params["domain"]
  second = params["second"]

  info = rand(90000)
  @resp={"domain"=>domain, "info"=>{"domain"=>domain, "registered"=>second, "expires"=>info}}
  #@resp["domain"]=domain
  #content_type :json
# {  => domain, "info" => {"available" => true, "registered" => true, "expires" => info} }
  json @resp, :layout => nil
end