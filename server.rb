require 'rubygems'
require 'open-uri'
require 'sinatra'
require 'json'
require 'cgi'
require 'active_record'
require 'net/https'

ActiveRecord::Base.establish_connection(
 :adapter => "mysql",
 :host => "localhost",
 :database => "osu_events",
 :password => "tarun123",
 :pool => 8
)

class Event_Details < ActiveRecord::Base
end

class Users < ActiveRecord::Base
end

class Categories < ActiveRecord::Base
end

class Fb_User_Connections < ActiveRecord::Base
end

get '/' do
    headers({"Content-Type" => "text/html; charset=ISO-8859-1"})
    "OSU Events"
end

get '/new_user' do
    res = Users.create()
    headers({"Content-Type" => "text/html; charset=ISO-8859-1"})
    {"result" => {"status" => true, "data" => res.user_id }}.to_json
end

get '/connect_user' do
    fb_id = params[:fb_id]
    current_user_id = params[:user_id]
    fb_access_token = params[:fb_access_token]
    user_name = params[:user_name]
    user = Users.update(current_user_id, {:fb_id => fb_id, :fb_access_token => fb_access_token, :user_name => user_name})
    if (user.fb_id.nil?)
        return {"result" => {"status" => false, "data" => {"user_id" => user.user_id, "fb_user_id" => user.fb_id, "fb_access_token" => user.fb_access_token, "user_name" => user.user_name} }}.to_json
    else
        return {"result" => {"status" => true, "data" => {"user_id" => user.user_id, "fb_user_id" => user.fb_id, "fb_access_token" => user.fb_access_token, "user_name" => user.user_name} }}.to_json
    end
end

get '/get_event_details' do
    event_id = params[:event_id]
    puts event_id
    event_details = Event_Details.find(event_id)
    if (event_details.nil?)
        return {"result" => {"status" => false, "data" => nil }}.to_json
    else
        return {"result" => {"status" => true, "data" => {
            "event_id" => event_details.event_id,
            "name" => event_details.name,
            "start_date" => event_details.start_date,
            "end_date" => event_details.end_date,
            "contact_email"=> event_details.contact_email,
            "contact_name" => event_details.contact_name,
            "contact_number" => event_details.contact_number,
            "category" => event_details.category,
            "event_type" => event_details.event_type,
            "event_link" => event_details.event_link,
            "details_link" => event_details.details_link,
            "location" => event_details.location,
            "description" => event_details.description }}}.to_json
    end
end

get '/get_events' do
    num_events = params[:num_events]
    last_event_id = params[:last_event_id]
    category_id = params[:category_id]

    if (num_events.nil?) 
        num_events = 50
    end
    
    if (last_event_id.nil?)
        if (category_id.nil?)
            events = Event_Details.find(:all,:select => ["event_id", "name", "location", "start_date", "end_date", "category"], 
                           :limit => num_events, :order => "event_id", :conditions => ["start_date >= ?", Date.today])
        else
            events = Event_Details.find(:all,:select => ["event_id", "name", "location", "start_date", "end_date", "category"], 
                           :limit => num_events, :order => "event_id", :conditions => ["start_date >= ? AND category = ?", Date.today, category_id])
        end
    else
        if (category_id.nil?)    
            events = Event_Details.find(:all, :select => ["event_id", "name", "location", "start_date", "end_date", "category"], 
                           :limit => num_events, :order => "event_id", :conditions => ["start_date >= ? AND event_id > ?", Date.today, last_event_id])
        else
            events = Event_Details.find(:all, :select => ["event_id", "name", "location", "start_date", "end_date", "category"], 
                           :limit => num_events, :order => "event_id", :conditions => ["start_date >= ? AND event_id > ? AND category = ?", Date.today, last_event_id,  category_id])
        end
    end
    
    if (events.nil?)
            return {"result" => {"status" => false, "data" => nil }}.to_json
    else
        events_array = []
        events.map{ |e| 
            event = Hash.new()
            event["id"] = e.event_id
            event["name"] = e.name
            event["location"] = e.location
            event["start_date"] = e.start_date
            event["end_date"] = e.end_date
            event["category"] = e.category
            events_array.push(event)
        }
        return {"result" => {"status" => true, "data" => events_array }}.to_json
    end

end

get '/get_event_categories' do
    categories = Category.find(:all)
    if (categories.nil?)
        return {"result" => {"status" => false, "data" => nil }}.to_json
    else
        category_array = []
        categories.map{ |c| 
            category = Hash.new()
            category["id"] = c.category_id
            category["name"] = c.category_title
            category_array.push(category)
        }
        return {"result" => {"status" => true, "data" =>  category_array}}.to_json
    end 
end

get '/fb' do
    http = Net::HTTP.new('graph.facebook.com', 443)
    http.use_ssl = true
    user_id = 513858558
    #path = '/885010384/friends?access_token=AAAFMmFSEZCykBANAOfZAUQlG0Vh4QKrjLRqIYfUPLTOF1MZCYbgsfU3666rCZAGCpatT3y4rI6nVhDU40ESejQZBPe8iUjZCOZAppteBCZC7ewZDZD'
    #path = '/692740909/friends?access_token=AAAFMmFSEZCykBALp1ifcvYc18nnlHtkCKPivyhYeVuYRF61XG0mHbwL67PzsZBIa6ccsXZCt7N0wK1jaMBRDQjASRZCZBQ6mIzfK0oPkcWAZDZD'
    path = '/513858558/friends?access_token=AAAFMmFSEZCykBAFwrKMPbQl4kj0Lb5nRXeRqobntaWBCZBbhBP9GPlmdENxJvdJ5OwuvrNsTWi5K9gCp0i4YeOrv3BBG5ZBLquZAUrxo6AZDZD'
# 692740909 vinnet AAAFMmFSEZCykBALp1ifcvYc18nnlHtkCKPivyhYeVuYRF61XG0mHbwL67PzsZBIa6ccsXZCt7N0wK1jaMBRDQjASRZCZBQ6mIzfK0oPkcWAZDZD
#access_token=AAAFMmFSEZCykBAFwrKMPbQl4kj0Lb5nRXeRqobntaWBCZBbhBP9GPlmdENxJvdJ5OwuvrNsTWi5K9gCp0i4YeOrv3BBG5ZBLquZAUrxo6AZDZD&expires_in=6630
    # GET request -> so the host can set his cookies
    resp, data = http.get(path, nil)
    #puts data
    res = JSON.parse(data)
    res["data"].map { |v| 
        Fb_User_Connections.create(:fb_id => user_id, :fb_friend_id =>  v["id"])
    }
    return data
end

ActiveRecord::Base.connection.close
