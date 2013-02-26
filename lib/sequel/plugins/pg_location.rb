module Sequel
	module Plugins
		module PgLocation

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
