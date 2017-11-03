require_relative 'controllers/menu_controller'
require 'bloc_record'


 if BlocRecord.database.type = "sqlite3"
   BlocRecord.connect_to("db/address_bloc.db", :sqlite3)
 elsif BlocRecord.database.type = "pg"
   BlocRecord.connect_to("db/address_bloc.db", :pg)
 end

menu = MenuController.new
system "clear"
puts "Welcome to AddressBloc!"
menu.main_menu
#Test
