require 'rubygems'
require 'open-uri'
require 'sinatra'
require 'json'
require 'cgi'
require 'active_record'

ActiveRecord::Base.establish_connection(
 :adapter => "mysql",
 :host => "localhost",
 :database => "osu_events",
 :password => "tarun123"
)

class Event_Details < ActiveRecord::Base
end

class Users < ActiveRecord::Base
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
    if (num_events.nil?) 
        num_events = 50
    end
    if (last_event_id.nil?)
        events = Event_Details.find(:all,:select => ["event_id", "name", "location", "start_date", "end_date", "category"], 
                                    :limit => num_events, :order => "event_id", :conditions => ["start_date >= ?", Date.today])
        if (events.nil?)
            return {"result" => {"status" => false, "data" => nil }}.to_json
        else
            return {"result" => {"status" => true, "data" => events }}.to_json
        end
    else
        events = Event_Details.find(:all, :select => ["event_id", "name", "location", "start_date", "end_date", "category"], 
                                    :limit => num_events, :order => "event_id", :conditions => ["start_date >= ? AND event_id > ?", Date.today, last_event_id])
        if (events.nil?)
            return {"result" => {"status" => false, "data" => nil }}.to_json
        else
            return {"result" => {"status" => true, "data" => events }}.to_json
        end

    end
end


