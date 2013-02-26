module Sequel
 	module Postgres
		class PgLocation
			module DatabaseMethods
				def add_extension(name)
					quoted_name = quote_identifier(name) if name
					run("CREATE EXTENSION IF NOT EXISTS #{quoted_name}")
				end

				def drop_extension(name)
					quoted_name = quote_identifier(name) if name
					run("DROP EXTENSION IF EXISTS #{quoted_name}")
				end

				def add_location_trigger(table, op={})
					self.run("CREATE FUNCTION update_#{table.to_s}_ll_point() RETURNS TRIGGER AS 'BEGIN NEW.#{op[:earth_point] || "ll_point"}=ll_to_earth(NEW.#{op[:latitude] || "latitude"}, NEW.#{op[:longitude] || "longitude"}); return NEW; END;' LANGUAGE plpgsql;")
					self.run("CREATE TRIGGER trigger_#{table.to_s}_ll_point BEFORE INSERT OR UPDATE ON #{table.to_s} FOR ROW EXECUTE PROCEDURE update_#{table.to_s}_ll_point();")
				end

				def drop_location_trigger(table)
					self.run("DROP TRIGGER trigger_#{table.to_s}_ll_point ON #{table.to_s};")
					self.run("DROP FUNCTION update_#{table.to_s}_ll_point();")
				end
			end
		end
	end
	Database.register_extension(:pg_location, Postgres::PgLocation::DatabaseMethods)
end


