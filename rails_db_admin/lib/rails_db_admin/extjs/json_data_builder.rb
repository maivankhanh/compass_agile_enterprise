module RailsDbAdmin
  module Extjs
    class JsonDataBuilder

      def initialize(database_connection_class)
        @connection = database_connection_class.connection
      end

      def build_json_data(options)
        unless options[:table]
          raise '!Error Must specify table'
        end

        total_count = self.get_total_count(options[:table])
        arel_table = Arel::Table::new(options[:table])

        if options[:limit] && options[:offset] && options[:order]
          query = arel_table.project(Arel.sql('*')).order(options[:order]).
            take(@connection.sanitize_limit(options[:limit])).
            skip(options[:offset].to_i)
        elsif options[:limit] && options[:order]
          query = arel_table.project(Arel.sql('*')).order(options[:order]).
            take(@connection.sanitize_limit(options[:limit]))
        elsif options[:limit] && !options[:order]
          query = arel_table.project(Arel.sql('*')).
            take(@connection.sanitize_limit(options[:limit]))
        elsif !options[:limit] && options[:order]
          query = arel_table.project(Arel.sql('*')).order(options[:order])
        else
          query = arel_table.project(Arel.sql('*'))
        end

        #rows = @connection.select_all(query.to_sql)
        # i think the above straight sql query was done to handle straight sql, however it does not translate postgres boolean columns properly
        # since this method is only used on a single table we can use activerecord, leaving this comment in case I'm wrong
        rows = options[:table].classify.constantize.find_by_sql(query.to_sql)
        
        records = RailsDbAdmin::TableSupport.database_rows_to_hash(rows)

        if !records.empty? && !records[0].has_key?("id")
          records = RailsDbAdmin::TableSupport.add_fake_id_col(records)
        end

        {:total => total_count, :data => records}
      end

      def get_row_data(table, id)
        arel_table = Arel::Table::new(table)

        query = arel_table.project(
          Arel.sql('*')).where(arel_table[id[0].to_sym].eq(id[1]))

        rows = @connection.select_all(query.to_sql)
        records = RailsDbAdmin::TableSupport.database_rows_to_hash(rows)
        records[0]
      end

      #This will retrieve data from tables without an
      #'id' field.  Will also add a 'fake_id' so that it can
      #be used by editable ExtJS grids.
      def get_row_data_no_id(table, row_hash)

        arel_table = Arel::Table::new(table)
        query = arel_table.project(Arel.sql('*'))
        row_hash.each do |k, v|
          query = query.where(arel_table[k.to_sym].eq(v))
        end

        rows = @connection.select_all(query.to_sql)
        records = RailsDbAdmin::TableSupport.database_rows_to_hash(rows)
        records = RailsDbAdmin::TableSupport.add_fake_id_col(records)
        records[0]
      end

      def get_total_count(table)
        total_count = 0
        rows = @connection.select_all("SELECT COUNT(*) as count FROM #{table}")
        records = RailsDbAdmin::TableSupport.database_rows_to_hash(rows)
        total_count = records[0][:count]
			
        total_count
      end
	end
  end
end
