require 'sqlite3'
require 'pg'
require 'bloc_record/schema'

module Persistence
  def self.included(base)
    base.extend(ClassMethods)
  end

  def save!
    unless self.id
      self.id = self.class.create(BlocRecord::Utility.instance_variable_to_hash(self)).id
      BlocRecord::Utility.reload_obj(self)
      return true
    end

    fields = self.class.attributes.map { |col| "#{col}=#{BlocRecord::Utility.sql_strings(self.instance_variable_get("@#{col}"))}"}.join(",")

    sql =<<-SQL
      UPDATE #{self.class.table}
      SET #{fields}
      WHERE id = #{self.id};
    SQL

    self.class.connection.execute sql

    true
  end

  def save
    self.save! rescue false
  end

  def update_attributes(attribute, value)
    self.class.update(self.id, { attribute => value })
  end

  def update_attributes(updates)
    self.class.update(self.id, updates)
  end

  module ClassMethods

    def destroy(*id)
      if id.length > 1
        where_clause = "WHERE id IN (#{id.join(",")});"
      else
        where_clause = "WHERE id in #{id.first};"
      end

      connection.execute <<-SQL
        DELETE FROM #{table} #{where_clause}
      SQL

      true
    end

    def destroy
      self.class.destroy(self.id)
    end

    def destroy_all(val)
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
          WHERE #{conditions};
        SQL
      else
        connection.execute <<-SQL
        DELETE FROM #{table};
        SQL
      end

      true
    end

    def update_all(updates)
      update(nil, updates)
    end

    def create(attrs)
      attrs = BlocRecord::Utility.convert_keys(attrs)
      attrs.delete "id"
      vals = attributes.map { |key| BlocRecord::Utility.sql_strings(attrs[key]) }

      sql =<<-SQL
        INSERT INTO #{table} (#{attributes.join ","})
        VALUES (#{vals.join ","})
      SQL

      connection.execute sql

      data = Hash[attributes.zip attrs.values]
      data["id"] = connection.execute("SELECT last_insert_rowid();")[0][0]
      new(data)
    end

    def update(ids, updates)
      ids = self.map(&:id)

      if updates.class == Hash
        updates.each_with_index { |array, index| update(ids[index], array) }
      else
        updates = BlocRecord::Utility.convert_keys(updates)
        updates.delete "id"

        updates_array = updates.map { |key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}" }
      end

      if ids.class == Fixnum
        where_clause = "WHERE id IN (#{ids.join(",")});"
      elsif ids.class = Array
        where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
      else
        where_clause = ";"
      end

      connection.execute <<-SQL
        UPDATE #{table}
        SET #{updates_array * ","} #{where_clause}
      SQL

        true
    end

    def self.method_missing(method_name, *args, &block)
      if method_name.to_s =~ /update_(.*)/
        update_($1, *args[0])
      else
        super
      end
    end
  end
end
