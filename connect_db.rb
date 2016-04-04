# DB = Sequel.sqlite('database.db')
DB = Sequel.postgres(:host=>'192.168.0.7', :user=>'postgres', :password=>'postgres', :database=>'discount')
