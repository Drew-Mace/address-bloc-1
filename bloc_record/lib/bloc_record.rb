module BlocRecord
 def self.connect_to(filename, arg)
   arg = arg.to_sym
   @database_filename = filename
 end

 def self.database_filename
   @database_filename
 end
end
