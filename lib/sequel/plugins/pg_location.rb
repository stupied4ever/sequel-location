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

        Plugins.def_dataset_methods(self, :near_to)
      end

      module DatasetMethods
        def near_to(lat, lng)
          location_cache_field = model.location_cache_field

          select_append{ Sequel::SQL::AliasedExpression.new(
            Sequel.function(:earth_distance,
              Sequel.function(:ll_to_earth, lat, lng),
                location_cache_field), :distance)
          }.order(Sequel.asc(Sequel.lit("distance")))
        end

        def near_within(lat, lng, radius)
          within(lat, lng, radius).near_to(lat, lng)
        end

        def within(lat, lng, radius)
          location_cache_field = model.location_cache_field

          where("earth_box(ll_to_earth(?,?),?) @> #{location_cache_field}", lat, lng, radius).
            where("earth_distance(ll_to_earth(?, ?), #{location_cache_field}) < ?", lat, lng, radius)
        end
      end
    end
  end
end
