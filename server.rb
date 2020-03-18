# frozen_string_literal: true

require 'bundler'
Bundler.require
require 'sinatra/config_file'
require 'haml'
require 'pp'
require 'httparty'
require 'json'
require 'active_support/all'
HTTParty::Basement.default_options.update(verify: false)

config_file './config.yml'
set :bind, '0.0.0.0'

PER_PAGE = 100
DATE_FORMAT = '%d-%m-%Y'

get '/callback' do
  @purl = purl
  @code = params[:code]
  @result = JSON.parse(retrieve_tokens(grant_type: 'authorization_code', code: @code).body)
  haml :callback, layout: :application
end

get '/stylesheets/*.css' do
  content_type 'text/css', charset: 'utf-8'
  filename = params[:splat].first
  scss filename.to_sym, views: './stylesheets'
end

get '/' do
  @purl = purl
  haml :index, layout: :application
end

post '/polar_api_v1' do
  json read_from_api(params).body
end

# Exports

get '/export_all.json' do
  @token = params[:token]
  @teams = parse_json_from_api('teams')
  @result = {}
  export_range(team_name: 'FC Groningen o.23', start_date: '27-06-2016', end_date: '15-05-2017')
  export_range(team_name: 'FC Groningen o.23', start_date: '02-07-2017', end_date: '23-05-2018')
  export_range(team_name: 'FC Groningen O.17', start_date: '29-08-2016', end_date: '23-04-2017')
  export_range(team_name: 'FC Groningen O.17', start_date: '07-08-2017', end_date: '29-05-2018')
  export_range(team_name: 'FC Groningen O.19', start_date: '29-08-2016', end_date: '23-04-2017')
  export_range(team_name: 'FC Groningen O.19', start_date: '07-08-2017', end_date: '29-05-2018')
  write_and_return_result(filename: 'export_all.json')
end

get '/export_range_that_has_data.json' do
  @token = params[:token]
  @teams = parse_json_from_api('teams')
  @result = {}
  export_range(team_name: 'FC Groningen O.17', start_date: '29-08-2019', end_date: '01-01-2020')
  write_and_return_result(filename: 'export_range_that_has_data.json')
end

get '/export_17_feb.json' do
  @token = params[:token]
  @teams = parse_json_from_api('teams')
  @result = {}
  export_range(team_name: 'Eerste selectie', start_date: '16-02-2020', end_date: '18-02-2020')
  write_and_return_result(filename: 'export_17_feb.json')
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
                  'Content-Type' => 'application/x-www-form-urlencoded'
                },
                body: params)
end

def read_from_api(params)
  HTTParty.get("https://teampro.api.polar.com/v1/#{params[:url]}",
               headers: {
                 'Accept' => 'application/json',
                 'Authorization' => "Bearer #{params[:token]}"
               })
end

def parse_json_from_api(url)
  @bucket ||= 50
  @bucket -= 1
  sleep(1) if @bucket.negative?
  JSON.parse(read_from_api(url: url, token: @token).body)
end

def paginate_all_data(url:, more_params: nil)
  query_params = "since=#{@start_date}&until=#{@end_date}#{more_params ? "&#{more_params}" : ''}"
  total_count = parse_json_from_api("#{url}?#{query_params}")['page']['total_elements']
  puts "total count: #{total_count}"
  idx = 0
  result = []
  while idx * PER_PAGE < total_count
    result += parse_json_from_api("#{url}?page=#{idx}&per_page=#{PER_PAGE}&#{query_params}")['data']
    idx += 1
  end
  puts "ERROR: result.length #{result.length} != total_count #{total_count}" if result.length != total_count
  result
end

def export_range(team_name:, start_date:, end_date:)
  dstart_date = Date.strptime(start_date, DATE_FORMAT)
  dend_date = Date.strptime(end_date, DATE_FORMAT)
  key = "#{team_name} #{dstart_date.strftime(DATE_FORMAT)} - #{dend_date.strftime(DATE_FORMAT)}"
  @result[key] = export_range_aux(team_name: team_name,
                                  start_date: dstart_date.to_s(:db),
                                  end_date: dend_date.to_s(:db))
end

def write_and_return_result(filename:)
  File.open(filename, 'w') do |f|
    f.puts @result.to_json
  end
  json @result
end

def export_range_aux(team_name:, start_date:, end_date:)
  @start_date = format_date(start_date)
  @end_date = format_date(end_date)
  @team_id = team_id(team_name)
  {
    team_training_sessions: team_training_sessions
    # team_details: team_details
  }
end

def format_date(date_string)
  "#{date_string}T00:00:00Z"
end

def team_id(team_name)
  (@teams['data'].find { |team| team['name'] == team_name })['id']
end

def team_training_sessions
  data = paginate_all_data(url: "teams/#{@team_id}/training_sessions")
  data.map do |entry|
    entry.merge!(parse_json_from_api("teams/training_sessions/#{entry['id']}")['data'])
  end
end

def team_details
  team_details = parse_json_from_api("teams/#{@team_id}")['data']
  @players = team_details['players']
  {
    team_details: team_details,
    player_training_sessions: players_training_sessions
  }
end

def players_training_sessions
  result = {}
  @players.each do |player|
    @player_id = player['player_id']
    result[@player_id] = player_training_sessions
  end
  result
end

def player_training_sessions
  data = paginate_all_data(url: "players/#{@player_id}/training_sessions", more_params: 'type=ALL')
  data.map do |entry|
    entry['details'] = parse_json_from_api("training_sessions/#{entry['id']}")['data']
    entry
  end
end
