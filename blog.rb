require 'rubygems'
require 'sinatra'
require 'mongo'
require 'bson'
require 'uri'

#is for output in the console using foreman start
$stdout.sync = true 

#Connects us to Database hosted as heroku addon on mongo hq look here: https://devcenter.heroku.com/articles/mongohq#use-with-ruby
dbConfig = URI.parse(ENV['MONGOHQ_URL'])
db_name = dbConfig.path.gsub(/^\//, '')
db = Mongo::Connection.new(dbConfig.host, dbConfig.port).db(db_name)
db.authenticate(dbConfig.user, dbConfig.password) unless (dbConfig.user.nil? || dbConfig.user.nil?)


#setting variable db equal to database

#List all users in collection 'namen' + delete & update link 
get '/' do
	#reads collection 'namen' & transforms into array
	telefonbuch = db['namen'].find().to_a
	#result = apply block to every element in telefonbuch & join elements with break in between
	result = telefonbuch.map{|document| "<a href='delete?id=#{document['_id']}'>Delete</a>||<a href='update?id=#{document['_id']}'>Update</a>||#{document['nachname']}, #{document['vorname']}, #{document['nummer']} "}.join("<br>")
	#Adds link to get '/new'
	result = result + '<br><br><a href="new">New Entry</a>' + '<br><br><form method = "post" action ="search">
	<input name="tosearch" type="text" placeholder="Search"></input>
	<button>Go search!</button>
	</form>'
	#returns the result
	result
end

post '/search' do
#get input from search in get '/'
search = params[:tosearch]
#debugging
puts "Input was = #{search}"
#search for search entry in our database
entries = db['namen'].find({'$or' => [{:vorname => search.downcase.split(" ").map(&:capitalize).join(" ")}, {:nachname => search.downcase.split(" ").map(&:capitalize).join(" ")}, {:nummer => search}]}).to_a 
#debugging
puts entries
	if entry = entries[0]
		puts entry
		vorname = entry["vorname"]
		nachname = entry["nachname"]
		nummer = entry["nummer"]
		"Found someone: <br><br>His Majesty: #{vorname} #{nachname}<br><br>His number: #{nummer}<br><br><a href='/'>Back</a>"
	else
		"Sorry, no entry found!<br><br><a href='/'>Back</a>"
	end
#end
end

#Opens form to fill in names 
get '/new' do
	#renders our form in html and sends it to post '/new'
	'<form method="post" action="new">
		<input name="vorname" type="text" placeholder="First name"></input><br>
		<input name="nachname" type="text" placeholder="Last name"></input><br>
		<input name="nummer" type="text" placeholder="Phone number"></input>
		<button>Save</button>
	</form>'
end

#Adds new user to database and confirms it
post '/new' do
#set variables for data from form
     vorname = params[:vorname]
     nachname = params[:nachname]
     nummer = params[:nummer]
     #for debugging in console
     puts "#{params}"
     #feed collection namen inside database with the values passed from get '/new' via params
     db['namen'].insert({:vorname=> vorname.downcase.split(" ").map(&:capitalize).join(" "), :nachname=> nachname.downcase.split(" ").map(&:capitalize).join(" "), :nummer => nummer})
     #confirm adding and provide links to get '/' and get '/new'
     "#{nachname}, #{vorname},#{nummer} have been added! <a href='new'>New Entry</a> <a href='/'>All</a> "
end

#Delete a user from database
get '/delete' do
    #gets id to delete from get '/delete?id=#{document['_id']}'
    id = params[:id]
    #removes entry with that id from database
	db['namen'].remove({:_id=> BSON::ObjectId.from_string(id)})
	#confirms removal and provides links to get '/new' and get '/'
     "Entry with the ID:#{id} was removed! <a href='new'>New Entry</a> <a href='/'>All</a> "
end

#Give 'new' form with current user
get '/update' do
	#gets ID to update from get 'update?id=#{document['_id']}''
	id = params[:id]
	#find ID in database and convert to array
	persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
	#convert array database object to hash entry
	person = persons[0]
	#debugging on console
	puts "#{persons}"
	puts "#{person}"
	#set vorname, nachname equal to person hash entries
	vorname = person["vorname"]
	nachname = person["nachname"]
	nummer = person["nummer"]
	#debugging
	puts "#{vorname}"
	puts "#{nachname}"
	#form that contains current names and sends ID to post '/update'
	 %{<form method="post" action="update?id=#{id}">
		<input name="vorname" type="text" placeholder="First name" value="#{vorname}"></input><br>
		<input name="nachname" type="text" placeholder="Last name" value="#{nachname}"></input><br>
		<input name="nummer" type="text" placeholder="Phone number" value="#{nummer}"></input><br>
		<button>Save</button>
	</form>}

end

#updates database with new entry
post '/update' do
	#debugging
	print params
	#gets ID to update from get 'update?id=#{id}'
	id = params[:id]
	#gets new names from form
	vorname = params[:vorname]
	nachname = params[:nachname]
	nummer = params[:nummer]
	#find correlating database entry and convert to hash object
	persons = db['namen'].find({:_id=> BSON::ObjectId.from_string(id)}).to_a
	person = persons[0]
	#fill hash with new names from form
	person["vorname"] = vorname.downcase.split(" ").map(&:capitalize).join(" ")
	person["nachname"] = nachname.downcase.split(" ").map(&:capitalize).join(" ")
	person["nummer"] = nummer.downcase.split(" ").map(&:capitalize).join(" ")
	#save new entries from person hash to database
	db['namen'].save(person)
	#updated message
     "#{nachname}, #{vorname},#{nummer} has been updated! <a href='new'>New</a> <a href='/'>All</a> "

end




