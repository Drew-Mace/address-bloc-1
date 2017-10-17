require 'sqlite3'

module Connection
 def connection
   puts BlocRecord.instance_methods
   @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
 end
end