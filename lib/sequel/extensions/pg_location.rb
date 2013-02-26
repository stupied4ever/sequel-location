module Sequel
	module Postgres
		class AlterTableGenerator < Sequel::Schema::AlterTableGenerator
			def add_location_trigger(options={})
				@operations << {:op=>:create_location_function}.merge(options)
				@operations << {:op=>:create_location_trigger}
			end

			def drop_location_trigger(options={})
				@operations << {:op=>:drop_location_trigger}
				@operations << {:op=>:drop_location_function}
			end
		end

		class Database < Sequel::Database
			def add_extension(name)
				quoted_name = quote_identifier(name) if name
				run("CREATE EXTENSION IF NOT EXISTS #{quoted_name}")
			end

			def drop_extension(name)
				quoted_name = quote_identifier(name) if name
				run("DROP EXTENSION IF EXISTS #{quoted_name}")
			end

			def alter_table_sql(table, op)
				case op[:op]
				when :create_location_function 
					self.run("CREATE FUNCTION update_#{table.to_s}_ll_point() RETURNS TRIGGER AS 'BEGIN NEW.#{op[:earth_point] || "ll_point"}=ll_to_earth(NEW.#{op[:latitude] || "latitude"}, NEW.#{op[:longitude] || "longitude"}); return NEW; END;' LANGUAGE plpgsql;")
				when :create_location_trigger
					self.run("CREATE TRIGGER trigger_#{table.to_s}_ll_point BEFORE INSERT OR UPDATE ON #{table.to_s} FOR ROW EXECUTE PROCEDURE update_#{table.to_s}_ll_point();")
				when :drop_location_trigger
					self.run("DROP TRIGGER trigger_#{table.to_s}_ll_point ON #{table.to_s};")
				when :drop_location_function
					self.run("DROP FUNCTION update_#{table.to_s}_ll_point();")
				else
					super(table,op)
				end
			end
		end
	end
end


