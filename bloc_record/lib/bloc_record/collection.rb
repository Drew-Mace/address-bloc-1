require 'sqlite3'
require 'pg'

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
        SELECT #{attrs.join (",")}
        FROM #{table}
        WHERE #{value.join (",")};
       SQL

       output
     end

     def destroy_all(val, ids)
       if val.class == String
         conditions = val.to_s
       elsif val.class == Hash
         conditions_hash = BlocRecord::Utility.convert_keys(conditions_hash)
         conditions = conditions_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
       elsif val.class == Array
         conditions = val.join(",")
       end

       if conditions
         connection.execute <<-SQL
           DELETE FROM #{table}
           WHERE #{conditions}
           AND id IN (#{ids.join (",")});
         SQL
       else
         connection.execute <<-SQL
         DELETE FROM #{table}
         WHERE id IN (#{ids.join (",")});
         SQL
       end

       true
     end

     def not(attrs, value)
       attrs = BlocRecord::Utility.convert_keys(attrs)
       attrs.delete "id"
       value = value.map { |key| BlocRecord::Utility.sql_strings(value[key]) }

       output = connection.execute <<-SQL
        SELECT #{attrs.join (",")}
        FROM #{table}
        WHERE != #{value.join (",")};
       SQL

       output
     end
   end
 end
