require 'sqlite3'
require 'sequel'

require './connect_db.rb'

DB.create_table?(:cashes)do
	primary_key :id
	String :names
	Integer :percent, :default => 10
end