require 'bundler' ; Bundler.require
require 'sinatra/config_file'
require 'haml'
require 'pp'
require 'httparty'
HTTParty::Basement.default_options.update(verify: false)

config_file './config.yml'

get '/callback' do
  @purl = purl
  @code = params[:code]
  @result = JSON.parse(retrieve_tokens(grant_type: 'authorization_code', code: @code).body)
  haml :callback, layout: :application
end

get '/stylesheets/*.css' do
  content_type 'text/css', :charset => 'utf-8'
  filename = params[:splat].first
  scss filename.to_sym, :views => './stylesheets'
end

get '/' do
  @purl = purl
  haml :index, layout: :application
end

post '/polar_api_v1' do
  json read_from_api(params).body
end

private

def purl
  "https://auth.polar.com/oauth/authorize?client_id=#{settings.client_id}&response_type=code&scope=team_read"
end

def basicauth_header
  "Basic #{Base64.strict_encode64("#{settings.client_id}:#{settings.client_secret}")}"
end

def retrieve_tokens(params)
  HTTParty.post('https://auth.polar.com/oauth/token',
                headers: {
                  'Authorization' => basicauth_header,
                  'Content-Type' => 'application/x-www-form-urlencoded',
                },
                body: params)
end

def read_from_api(params)
  HTTParty.get("https://teampro.api.polar.com/v1/#{params[:url]}",
               headers: {
                 'Accept' => 'application/json',
                 'Authorization' => "Bearer #{params[:token]}",
               })
end
