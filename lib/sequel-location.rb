module Sequel
	module Plugins
		module Location

			def self.configure(model, opts={})
				model.instance_eval do
					@location_cache_field = opts[:earth_point] ||= :ll_point
				end
			end

			module ClassMethods
				attr_reader :location_cache_field

				def inherited(subclass)
					super
					subclass.instance_variable_set(:@location_cache_field, instance_variable_get(:@location_cache_field))
				end
			end

			module DatasetMethods
				def nearest(lat,lng,radius)
					location_cache_field = model.location_cache_field
					radius_in_km = (radius.to_i * 1609.3).to_f
					lat = lat.to_f
					lng = lng.to_f
					where("earth_box(ll_to_earth(?,?),?) @> #{location_cache_field}", lat, lng, radius_in_km).where("earth_distance(ll_to_earth(?, ?), #{location_cache_field}) < ?", lat, lng, radius_in_km).select_append{
						(Sequel.function(:earth_distance, Sequel.function(:ll_to_earth,lat,lng), location_cache_field)).as(distance)
						}.order(:distance)
				end
			end
		end
	end
end

module Sequel
	module Postgres
		class AlterTableGenerator
			def add_location_trigger(options={})
				@operations << {:op=>:create_location_function}.merge(options)
				@operations << {:op=>:create_location_trigger}
			end

			def drop_location_trigger(options={})
				@operations << {:op=>:drop_location_trigger}
				@operations << {:op=>:drop_location_function}
			end
		end

		class Database
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


