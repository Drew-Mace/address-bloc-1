require 'sqlite3'

 module BlocRecord
   class Collection < Array

     def update_all(updates)
       ids = self.map(&:id)

       self.any? ? self.first.class.update(ids, updates) : false
     end

     def take(attrs, value)
       attrs = BlocRecord::Utility.convert_keys(attrs)
       attrs.delete "id"
       value = values.map { |key| BlocRecord::Utility.sql_strings(value[key]) }

        output = connection.execute <<-SQL
          SELECT #{attrs}
          FROM #{table}
          WHERE #{value};
        SQL

      output
     end

     def where(attrs, value)
       attrs = BlocRecord::Utility.convert_keys(attrs)
       attrs.delete "id"
       value = value.map { |key| BlocRecord::Utility.sql_strings(value[key]) }

       output = connection.execute <<-SQL
        SELECT #{attrs}
        FROM #{table}
        WHERE #{value[0]} AND  #{value[1]};
       SQL

       output

     end

     def where(attrs, value)
       attrs = BlocRecord::Utility.convert_keys(attrs)
       attrs.delete "id"
       value = value.map { |key| BlocRecord::Utility.sql_strings(value[key]) }

       output = connection.execute <<-SQL
        SELECT #{attrs}
        FROM #{table}
        WHERE != #{value};
       SQL

       output

     end
   end
 end
