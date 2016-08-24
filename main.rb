require 'sinatra'
require 'sinatra/json'
require './bd_uses.rb'
require 'haml'
require 'xmlsimple'
require 'sinatra/respond_with'
require "sinatra/reloader" if development?

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
  session['user']=Cashe[params['user']].name
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
  session['cart'] = ''
  session['new_cart']=''
  session['family']=''
  session['name']=''
  session['surname']=''
  session['city']=''
  session['mobile']=''
  session['birthday']=''
  haml :'clients/list'
end

post '/clients.ajax' do
  cart=params["cart"]
  unless cart.empty?
    cart="0"+cart if cart[0]!="0"
    cart.gsub!(' ','')
    session['cart']=cart
    return json DB[:clients].left_join(:cards, :client_id=>:id).left_join(:bonuses, :card_id=>:id).where(:clients__id=>DB[:cards].where(:barcode=>cart).select(:client_id))\
                    .group(:clients__id).select(:clients__id,:clients__family,:clients__name,:clients__surname,:clients__mobile)\
                    .select_append{max(:barcode).as('cart')}.select_append{sum(:value).as(bonus)}.limit(20).all
  end
  filter=params["filter"]
  unless filter.empty?
    str=""
    filter.split(' ').each { |fl|
      if str==""
        str=Sequel.|(Sequel.ilike(:family,"#{fl}%"),Sequel.ilike(:name,"#{fl}%"),Sequel.ilike(:surname,"#{fl}%"),Sequel.ilike(:mobile,"%#{fl}"))
      else
        str=Sequel.&(str,Sequel.|(Sequel.ilike(:family,"#{fl}%"),Sequel.ilike(:name,"#{fl}%"),Sequel.ilike(:surname,"#{fl}%"),Sequel.ilike(:mobile,"%#{fl}")))
      end
    }
    return json DB[:clients].left_join(:cards, :client_id=>:id).left_join(:bonuses, :card_id=>:id).where(str)\
                    .group(:clients__id).select(:clients__id,:clients__family,:clients__name,:clients__surname,:clients__mobile)\
                    .select_append{max(:barcode).as('cart')}.select_append{sum(:value).as(bonus)}.limit(20).all
  end
  json DB[:clients].left_join(:cards, :client_id=>:id).left_join(:bonuses, :card_id=>:id).group(:clients__id)\
                    .select(:clients__id,:clients__family,:clients__name,:clients__surname,:clients__mobile)\
                    .select_append{max(:barcode).as('cart')}.select_append{sum(:value).as(bonus)}.limit(20).all
  #json { :domain => domain, :info => {:available => info.available?, :registered => info.registered?, :expires => info.expires_on} } unless info.nil?
end

get '/client/cart' do
  @hsh={:cart=>session['cart']}
  session['cart']=''
  haml :'clients/cart'
end

post '/client/cart' do
  cart=params["cart"];
  session['cart']=cart
  cart.gsub!(' ','')
  if cart.empty?
    session['secret']='Нужно обязательно заполнить карту!'
    redirect to('/client/cart')
  end
  prefix=cart[0..4]
  if ['01500','15000'].include?(prefix) then
  else
    session['secret']='Регистрируем только фирменную карту!'
    redirect to('/client/cart')
  end
  cart='0'+cart if prefix=='15000'
  if cart.length!=13 then
    session['secret']='Ошибочный номер карты!'
    redirect to('/client/cart')
  end
  unless Card.where(Sequel.&(Sequel.~(:client_id => nil),:barcode=>cart)).first.nil? then
    session['secret']="Карта #{cart} уже добавлена!"
    redirect to('/client/cart')
  end
  session['secret']=''
  session['cart']=cart
  redirect to("client/new")
end

get '/client/new' do
  @hsh={:cart=>session['cart']}
  session['cart']=''
  haml :'clients/new'
end

post '/client/new' do
  # params.each{|key,value| puts "#{key} => #{value}"}
  cart = params['cart']
  fl_sms = (params['fl_sms']=='on')
  fl_pol = params['fl_pol']
  mobile = params['phone']
  if mobile.length<17
    mobile=''
    fl_sms=false;
  else
    mobile='7'+mobile[4..6]+mobile[9..11]+mobile[13..17]
  end
  #puts "'#{mobile}'"
  #puts session['user']

  #DB.transaction do
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
    if Card[{:barcode=>cart}].nil?
      crd = DB[:cards].insert({
                                  :barcode => cart,
                                  :client_id => clnt
                              })
    else
      Card[{:barcode=>cart}].update(:client_id => clnt)
      crd = Card[{:barcode=>cart}][:id]
    end
    if (params['fl_bonuses']=='on') then
      value = Float(params['bonuses']) rescue false
      Bonus.create({:card_id => crd, :cashe_id => session['cashe_id'], :value => value}) if value
    end
  #  raise Sequel::Rollback
  #end
  redirect to('/clients')
end

get '/client/:id/edit' do
  id=params[:id]
  cl=Client[id]
  @hsh={:cart=>Card[:client_id=>id][:barcode]}
  @hsh[:new_cart]=session['new_cart']
  @hsh[:family]=cl.family
  @hsh[:name]=cl.name
  @hsh[:surname]=cl.surname
  @hsh[:city]=cl.city
  @hsh[:mobile]=cl.mobile
  @hsh[:birthday]=cl.birthday
  @hsh[:m_f]=(cl.m_f!='m')
  @hsh[:sms]=cl.get_sms

  session['cart']=''
  session['new_cart']=''
  session['family']=''
  session['name']=''
  session['surname']=''
  session['city']=''
  session['mobile']=''
  session['birthday']=''
  haml :'clients/edit'
end

post '/client/:id/edit' do
  id=params[:id]
  type=params["tab"]
  if(type=="1")
    session['cart']=params["p1_old_cart"];
    session['new_cart']=params["p1_new_cart"];
    session['secret_type']=type;
    cart=params["p1_old_cart"];
    # puts cart
    cart.gsub!(' ','')
    if cart.empty?
      session['secret1']='Нужно обязательно заполнить карту!'
      redirect to("/client/#{id}/edit")
    end
    prefix=cart[0..3]
    if ['0130','1300'].include?(prefix) then
    else
      session['secret1']='Неверный номер старой карты!'
      redirect to("/client/#{id}/edit")
    end
    cart='0'+cart if prefix=='1300'
    if cart.length!=13 then
      session['secret1']='Ошибочный номер карты!'
      redirect to("/client/#{id}/edit")
    end
    c=Card[{:barcode=>cart, :client_id=>id}]
    if c.nil? then
      session['secret1']="Карта #{cart} у этого клиента не найдена!"
      redirect to("/client/#{id}/edit")
    end
    cart=params["p1_new_cart"];
    cart.gsub!(' ','')
    if cart.empty?
      session['secret2']='Нужно обязательно заполнить карту!'
      redirect to("/client/#{id}/edit")
    end
    prefix=cart[0..4]
    if ['01500','15000'].include?(prefix) then
    else
      session['secret2']='Неверный номер новой карты!'
      redirect to("/client/#{id}/edit")
    end
    cart='0'+cart if prefix=='15000'
    if cart.length!=13 then
      session['secret2']='Ошибочный номер карты!'
      redirect to("/client/#{id}/edit")
    end
    cc=Card[{:barcode=>cart}]
    unless cc.nil? then
      unless cc.client_id.nil?
        fl_new = true
        n_mobile = Client[cc.client_id][:mobile]
        o_mobile = Client[c.client_id][:mobile]
        if o_mobile!=n_mobile
          session['secret2']="Карта #{cart} уже добавлена у другого клиента!"
          redirect to("/client/#{id}/edit")
        else
          fl_new = false
        end
      end
      DB.transaction do
        if fl_new
          cc.update(:client_id=>c.client_id)
          Bonus.where(:card_id=>c[:id]).update(:card_id=>cc[:id])
          Payment.where(:card_id=>c[:id]).update(:card_id=>cc[:id])
          c.delete
        else
          Bonus.where(:card_id=>c[:id]).update(:card_id=>cc[:id])
          Payment.where(:card_id=>c[:id]).update(:card_id=>cc[:id])
          ud_client=c[:client_id]
          c.delete
          Client[ud_client].delete
        end
      end
    else
      c.update(:barcode=>cart)
    end
  elsif (type=="2")
    fl_sms = (params['fl_sms']=='true')
    fl_pol = params['fl_pol']
    mobile = params['phone']
    if mobile.length<17
      mobile=''
      fl_sms=false;
    else
      mobile='7'+mobile[4..6]+mobile[9..11]+mobile[13..17]
    end
    cl=Client[id]
    cl.update({:family=>params['surname'],
              :name=>params['name'],
              :surname=>params['lastname'],
              :m_f=>fl_pol,
              :birthday=>params['birthday'],
              :get_sms=>fl_sms,
              :active=>true,
              :mobile=>mobile,
              :city=>params['city'],
              :comments=>session['user']})
  else
      value = Float(params['bonuses']) rescue false
      Bonus.create({:card_id => Card[{:client_id=>id}][:id], :cashe_id => session['cashe_id'], :value => value}) if value
  end
  session['secret_type']=''
  session['secret1']=''
  session['secret2']=''
  session['cart']=''
  session['new_cart']=''
  redirect to("/clients")
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
