require 'sqlite3'
require 'pg'

module Connection
  def connection(connection)
    if connection == 'sqlite'
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    elsif connection == 'pg'
      @connection ||= Pg::Database.new(BlocRecord.database_filename)
    end
  end
end
