require 'rubygems'
require 'open-uri'
require 'sinatra'
require 'json'
require 'hpricot'
require 'cgi'
require 'active_record'
#require 'iconv'
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
    "OSU Events"
end

get '/test' do
	headers({"Content-Type" => "text/html; charset=ISO-8859-1"})
	erb("hello")
end

get '/new_user' do
    res = Users.create()
    puts res.user_id
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


