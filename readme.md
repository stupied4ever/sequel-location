#sequel-location
This gem gives you an easy setup and syntax for doing geolocation search in sequel.

**IMPORTANT: This will only work for postgres databases**

##Installation

````bash
gem install sequel-location
````

##Usage
sequel-location gives you access to a single dataset method, few helpers for doing the database
setup in migrations, and a nice syntax for configuring the plugin.

###Querying
Say you have an application that lets a user find the nearest bar to them (within ten miles). The resulting
query on your `Bar` model would be as follows.

````ruby
Bar.nearest(43.038513,-87.908913,10)
````

###Setup
````ruby
Sequel.migration do
	up do
		add_extension :cube						# required for earthdistance
		add_extension :earthdistance			# required for geolocation
		alter_table :bars do
			add_column :latitude, Decimal
			add_column :longitude, Decimal
			add_location_trigger				# provided by sequel-location to auto-calculate the earth point on update of latitude or longitude
			add_column :ll_point, 'earth' 		# ll_point is the default column for caching the caluclated earth point
			add_index :ll_point, :type=>:gist	# Not required, but suggested
		end
	end

	down do
		alter_table :bars do
			drop_index :ll_point
			drop_column :ll_point
			drop_column :longitude
			drop_column :latitude
			drop_location_trigger
		end
		drop_extension :earthdistance
		drop_extension :cube
	end
end
````

````ruby
class Bar < Sequel::Model
	plugin :location
end
````

You can specify the `:latitude` and `:longitude` parameters if you store your latitude and longitude in a
different column (e.g. `plugin :location :latitude=>:lat, :longitude=>:lng`)

You can also specify a `:earth_point` parameter if you want to cache your earth point in a different column
than `ll_point` (`plugin :location :earth_point=>:latitude_longitude_point_cache`)

**NOTE: If you specify a different latitude, longitude, or earth_point column, you need your migration to reflect the changes in the plugin configuration**

