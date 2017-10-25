require 'sqlite3'

module Selection

	def find(*ids)
    raise TypeError.new("id/s need to positive integers") unless ids.is_a? Numeric
		if ids.length == 1
			find(ids.first)
		else
			rows = connection.execute <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE id IN (#{ids.join(",")});
		 SQL
				rows_to_array(rows)
		end
		error_message_s
	end

	def find_one(id)
		raise TypeError.new("id must be a positive integer") unless id.is_a? Numeric
		row = connection.get_first_row <<-SQL
		 SELECT #{columns.join ","} FROM #{table}
		 WHERE id = #{id};
		SQL

		error_message_s
			init_object_from_row(row)
	end

	def find_one(attribute, value)
    raise TypeError.new("#{attribute} isn't a valid attribute") unless attribute.is_a? String
		row = connection.get_first_row <<-SQL
		 SELECT #{columns.join ","} FROM #{table}
		 WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
		SQL

		init_object_from_row(row)
	end

	def find_by(attribute, value)
    raise TypeError.new("#{attribute} isn't a valid attribute") unless attribute.is_a? String
		row = connection.get_first_row <<-SQL
 		SELECT #{columns.join ","} FROM #{table}
 		WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
 	 SQL

		init_object_from_row(row)
	end

	def take(num=1)
    raise TypeError.new("#{num} needs to be a positive integer") unless num.is_a? Numeric
		if num > 1
			rows = connection.execute <<-SQL
	 		 SELECT #{columns.join ","} FROM #{table}
	 		 ORDER BY random()
	 		 LIMIT #{num};
	 	  SQL
			error_message_s
			rows_to_array(rows)
		else
			take_one
		end
	end

	def take_one
		row = connection.get_first_row <<-SQL
		 SELECT #{columns.join ","} FROM #{table}
		 ORDER BY random()
		 LIMIT 1;
		SQL

		init_object_from_row(row)
	end

	def first
		row = connection.get_first_row <<-SQL
 	  SELECT #{columns.join ","} FROM #{table}
 	  ORDER BY id ASC LIMIT 1;
 	 SQL


		init_object_from_row(row)
	end

	def last
		row = connection.get_first_row <<-SQL
 	  SELECT #{columns.join ","} FROM #{table}
 		ORDER BY id DESC LIMIT 1;
 	 SQL


		init_object_from_row(row)
	end

 	def all
		rows = connection.execute <<-SQL
	   SELECT #{columns.join ","} FROM #{table};
	 	SQL

		rows_to_array(rows)
	end

	def self.method_missing(method_name, *args, &block)
		if method_name.to_s =~ /find_by_(.*)/
			find_by($1, *args[0])
		else
			super
		end
	end

	def find_each(hash)
    if hash
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY id
        LIMIT #{hash["batch_size"]} OFFSET #{hash["start"]};
      SQL
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY id;
      SQL
    end

    row_array = rows_to_array(rows)
    row_array.each do |row|
      yield(row)
    end
	end

	def find_in_batches(hash)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id
      LIMIT #{hash["limit"]} OFFSET #{hash["offset"]}
    SQL

    rows_to_array(rows)
	end

	def where(*args) ## where w/p params is the same as calling all columns in database
		if args.count > 1
			expression = args.shift
			params = args
		else
			case args.first
			when String
				expression = args.first
			when Hash
				expression_hash = BlocRecord::Utility.convert_keys(args.first)
				expression = expression_hash.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
			end
		end

    if args.count == 0
      rows = connection.execute <<-SQL
        SELECT * FROM #{table};
      SQL
    end

    sql =<<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{expression};
		SQL

		rows = connection.execute(sql, params)
		rows_to_array(rows)
	end

	def order(*args)
		if args.count > 1
			order = args.join(",")
		else
      case order.include?("DESC")
      when Hash
			  order = order.to_s
      when Symbol
        order = order.to_s
      when String
        order
      end
		end

		if order.include?("DESC")
			rows = connection.execute <<-SQL
				SELECT * FROM #{table}
				ORDER BY #{order} + "DESC";
			SQL
		end
		rows_to_array(rows)
	end


	def join(*args)
		if args.count > 1
			joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"  }.join(" ")
			rows = connection.execute <<-SQL
				SELECT * FROM #{table} #{joins}
			SQL
		else
			case args.first
			when String
				rows = connection.execute <<-SQL
					SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
				SQL
			when Symbol
				rows = connection.execute <<-SQL
					SELECT * FROM #{table}
					INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
					INNER JOIN #{args.second} ON #{args.second}.#{args.first}.#{table}_id = #{table}.id
				SQL
			end
		end

		rows_to_array(rows)
	end

	private
	def init_object_from_row(row)
		if row
			data = Hash[columns.zip(row)]
			new(data)
		end
	end

	def rows_to_array(rows)
		collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
	end
end
