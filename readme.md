#sequel-location
This gem gives you an easy setup and syntax for doing geolocation search in sequel.

**IMPORTANT: This will only work for postgres databases**

##Installation

````ruby
gem install sequel-location
````

##Usage
sequel-location gives you access to a single dataset method, a few helpers for doing the database
setup in migrations, and a nice syntax for configuring the plugin.

###Querying
For example, say you have an application that lets a user find the nearest bar to them (within ten miles). The resulting
query on your `Bar` model would be as follows.

````ruby
Bar.nearest(43.038513,-87.908913,10) # orders results by distance to location
Bar.within(43.038513,-87.908913,10)  # will not order results by distance
````

###Setup

````ruby
Sequel.migration do
	up do
		extension :pg_location
		add_extension :cube						# required for earthdistance
		add_extension :earthdistance			# required for geolocation
		add_location_trigger :bars				# provided by sequel-location to auto-calculate the earth point on update of latitude or longitude
		alter_table :bars do
			add_column :latitude, Decimal
			add_column :longitude, Decimal
			add_column :ll_point, 'earth' 		# ll_point is the default column for caching the caluclated earth point
			add_index :ll_point, :type=>:gist	# Not required, but suggested
		end
	end

	down do
		extension :pg_location
		alter_table :bars do
			drop_index :ll_point
			drop_column :ll_point
			drop_column :longitude
			drop_column :latitude
		end
		drop_location_trigger :bars
		drop_extension :earthdistance
		drop_extension :cube
	end
end
````

````ruby
# optional named parameters
# * :latitude=>:lat
# * :longitude=>:lng
# * :earth_point=>:longitude_latitude_cache
class Bar < Sequel::Model
	plugin :pg_location
end
````

###Options
####drop_location_trigger
* name - required `drop_location_trigger :bars`
* latitude - alternative latitude column (optional, default is `latitude`) `drop_location_trigger :bars, :latitude=>:lat`
* longitude - alternative longitude column (optional, default is `longitude`) `drop_location_trigger :bars, :longitude=>:lat`
* earth_point - alternative column for caching earth-point (optional, default is `ll_point`) `drop_location_trigger, :earth_point=>:latitude_longitude_cache`

You may specify any combination of the `latitude`, `longitude`, or `earth_point` options **but you must specify the same values in
your model plugin (if you're using one)**
