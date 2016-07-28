require 'sqlite3'
require 'sequel'

require './connect_db.rb'

DB.create_table?(:cashes) do
	primary_key :id
	String :name
	Integer :cashe_percent, :default => 10
end

DB.create_table?(:cards) do
  primary_key :id
  foreign_key :client_id
  String :barcode
  Integer :card_percent, :default => 10
  unique :barcode
end

DB.create_table?(:clients) do
  primary_key :id
  String :family
  String :name
  String :surname
  String :m_f
  String :birthday
  Boolean :get_sms
  Boolean :active
  String :mobile
  String :city
  String :email
  String :comments
  Integer :card_percent, :default => 10
end

DB.create_table?(:bonuses) do
  foreign_key :card_id
  foreign_key :cashe_id
  String :check_id
  Float :value
  DateTime :updated_at
  DateTime :created_at
end

DB.create_table?(:payments) do
  foreign_key :card_id
  foreign_key :cashe_id
  String :check_id
  Float :value
  DateTime :updated_at
  DateTime :created_at
end

DB.create_table?(:articles) do
  foreign_key :cashe_id
  String :check_id
  String :code
  String :article
  Float :quantity
  Float :sum
  DateTime :updated_at
  DateTime :created_at
end

class Cashe < Sequel::Model(:cashes)
  one_to_many :bonuses
end

class Card < Sequel::Model(:cards)
  one_to_many :bonuses
  many_to_one :clients
end

class Client < Sequel::Model(:clients)
  one_to_many :cards
end

class Bonus < Sequel::Model(:bonuses)
  plugin :timestamps
  many_to_one :cards
  many_to_one :cashes
end

class Payment < Sequel::Model(:payments)
  plugin :timestamps
  many_to_one :cards
  many_to_one :cashes
end

class Articles < Sequel::Model(:articles)
  plugin :timestamps
  many_to_one :cashes
end

