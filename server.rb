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

class MyApiError < StandardError
end

# Exports
################################################################################
# This is the one.
# Make sure to check that there are no unassigned players on https://teampro.polar.com/
get '/export_RecentlyAdjusted.json' do
  initialize_instance_variables
  #export_range(team_name: 'FC Groningen o16', start_date: '26-01-2022', end_date: '21-06-2022') # DONE
  #export_range(team_name: 'FC Groningen o18', start_date: '26-01-2022', end_date: '21-06-2022') # DONE
  #export_range(team_name: 'FC Groningen o21', start_date: '26-01-2022', end_date: '21-06-2022') # DONE
  #export_range(team_name: 'OUD FC Groningen o.23', start_date: '26-01-2022', end_date: '21-06-2022')# DONE, maar leeg
  #export_range(team_name: 'OUD FC Groningen o.23 (2)', start_date: '26-01-2022', end_date: '21-06-2022')# DONE, maar leeg
  #export_range(team_name: 'OUD FC GRONINGEN O.23 (3)', start_date: '26-01-2022', end_date: '21-06-2022') # DONE, maar leeg
  
  #export_range(team_name: 'FC Groningen o16', start_date: '11-11-2021', end_date: '26-01-2022') # DONE
  #export_range(team_name: 'FC Groningen o18', start_date: '11-11-2021', end_date: '26-01-2022') # DONE
  #export_range(team_name: 'FC Groningen o21', start_date: '11-11-2021', end_date: '26-01-2022') # DONE
  #export_range(team_name: 'OUD FC Groningen o.23', start_date: '11-11-2021', end_date: '26-01-2022') # DONE, maar leeg
  #export_range(team_name: 'OUD FC Groningen o.23 (2)', start_date: '11-11-2021', end_date: '26-01-2022') # DONE, maar leeg
  #export_range(team_name: 'OUD FC GRONINGEN O.23 (3)', start_date: '11-11-2021', end_date: '26-01-2022') # DONE, maar leeg
  
  export_range(team_name: 'Eerste selectie', start_date: '11-11-2021', end_date: '21-06-2022') # DONE
  write_and_return_result(filename: 'export_11112021_21062022_eerste.json')
end
get '/export_all_2020_2021.json' do
  initialize_instance_variables
  export_range(team_name: 'FC Groningen o16', start_date: '08-09-2020', end_date: '22-05-2021')
  export_range(team_name: 'FC Groningen o18', start_date: '08-09-2020', end_date: '22-05-2021')
  export_range(team_name: 'FC Groningen o21', start_date: '08-09-2020', end_date: '22-05-2021')
  export_range(team_name: 'OUD FC Groningen o.23', start_date: '08-09-2020', end_date: '22-05-2021')
  export_range(team_name: 'OUD FC Groningen o.23 (2)', start_date: '08-09-2020', end_date: '22-05-2021')
  write_and_return_result(filename: 'export_all_2020_2021.json')
end
################################################################################

get '/export_all.json' do
  initialize_instance_variables
  export_range(team_name: 'FC Groningen o.23', start_date: '27-06-2016', end_date: '15-05-2017')
  export_range(team_name: 'FC Groningen o.23', start_date: '02-07-2017', end_date: '23-05-2018')
  export_range(team_name: 'FC Groningen O.17', start_date: '29-08-2016', end_date: '23-04-2017')
  export_range(team_name: 'FC Groningen O.17', start_date: '07-08-2017', end_date: '29-05-2018')
  export_range(team_name: 'FC Groningen O.19', start_date: '29-08-2016', end_date: '23-04-2017')
  export_range(team_name: 'FC Groningen O.19', start_date: '07-08-2017', end_date: '29-05-2018')
  write_and_return_result(filename: 'export_all.json')
end

get '/export_all_new.json' do
  initialize_instance_variables
  export_range(team_name: 'FC Groningen o21', start_date: '07-09-2020', end_date: '02-10-2020')
  export_range(team_name: 'FC Groningen o18', start_date: '07-09-2020', end_date: '02-10-2020')
  export_range(team_name: 'FC Groningen o16', start_date: '07-09-2020', end_date: '02-10-2020')
  write_and_return_result(filename: 'export_all_new.json')
end

get '/export_range_that_has_data.json' do
  initialize_instance_variables
  export_range(team_name: 'FC Groningen O.17', start_date: '29-08-2019', end_date: '01-01-2020')
  write_and_return_result(filename: 'export_range_that_has_data.json')
end

get '/export_9_nov.json' do
  initialize_instance_variables
  export_range(team_name: 'FC Groningen o21', start_date: '09-11-2020', end_date: '10-11-2020')
  write_and_return_result(filename: 'export_9_nov.json')
end

get '/export_9_nov_all_samples.json' do
  initialize_instance_variables
  @samples = '?samples=all' # Don't use this, it's 78MB just for a single day.
  export_range(team_name: 'FC Groningen o21', start_date: '09-11-2020', end_date: '10-11-2020')
  write_and_return_result(filename: 'export_9_nov_all_samples.json')
end

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

private

def initialize_instance_variables
  @token = params[:token]
  @teams = parse_json_from_api('teams')
  @result = {}
  @samples = ''
  initialize_players
end

def initialize_players
  @player_number_mapping = {}
  @player_id_mapping = {}
  @player_ids = []
  @players = []

  data = paginate_all_data(url: 'teams')
  data.map do |team|
    cteam_details = parse_json_from_api("teams/#{team['id']}")['data']
    @players += cteam_details['players']
  end
  create_player_mappings
end

# rubocop:disable Metrics/AbcSize
def create_player_mappings
  @players.each do |player|
    @player_ids << player['player_id'] unless @player_ids.include?(player['player_id'])
    (@player_number_mapping[player['player_number']] ||= []) << player
    @player_number_mapping[player['player_number']].uniq!
    (@player_id_mapping[player['player_id']] ||= []) << player
    @player_id_mapping[player['player_id']].uniq!
  end
end
# rubocop:enable Metrics/AbcSize

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

# rubocop:disable Metrics/AbcSize
def parse_json_from_api(url)
  @bucket ||= 50
  @bucket -= 1
  sleep(1) if @bucket.negative?
  last_error_code = 429
  result = nil
  while last_error_code == 429
    result = JSON.parse(read_from_api(url: url, token: @token).body)
    return result if result['error'].blank?

    last_error_code = result['error']['status']
    # Sleep a minute if we get a too many requests error but keep trying
    sleep(60) if last_error_code == 429
  end
  error_message = "[#{Time.new.strftime('%k:%M')}] ERROR retrieving #{url}: \n#{result['error'].pretty_inspect}"
  puts error_message
  raise MyApiError, error_message
end
# rubocop:enable Metrics/AbcSize

# rubocop:disable Metrics/AbcSize
def paginate_all_data(url:, more_params: nil)
  query_params = "since=#{@start_date}&until=#{@end_date}#{more_params ? "&#{more_params}" : ''}"
  total_count = parse_json_from_api("#{url}?#{query_params}")['page']['total_elements']
  puts "[#{Time.new.strftime('%k:%M')}] total count for #{url}?#{query_params}: #{total_count}"
  idx = 0
  result = []
  while idx * PER_PAGE < total_count
    result += parse_json_from_api("#{url}?page=#{idx}&per_page=#{PER_PAGE}&#{query_params}")['data']
    idx += 1
  end
  puts "[#{Time.new.strftime('%k:%M')}] ERROR: result.length #{result.length} != total_count #{total_count}" if result.length != total_count
  result
rescue MyApiError
  []
end
# rubocop:enable Metrics/AbcSize

def export_range(team_name:, start_date:, end_date:)
  dstart_date = Date.strptime(start_date, DATE_FORMAT)
  dend_date = Date.strptime(end_date, DATE_FORMAT)
  key = "#{team_name} #{dstart_date.strftime(DATE_FORMAT)} - #{dend_date.strftime(DATE_FORMAT)}"
  @result[key] = export_range_aux(team_name: team_name,
                                  start_date: dstart_date.to_s(:db),
                                  end_date: dend_date.to_s(:db))
end

def write_and_return_result(filename:)
  File.open("exports/#{filename}", 'w') do |f|
    f.puts @result.to_json
  end
  json @result
end

def export_range_aux(team_name:, start_date:, end_date:)
  @start_date = format_date(start_date)
  @end_date = format_date(end_date)
  @team_name = team_name
  @team_id = team_id(team_name)
  {
    team_details: team_details,
    team_training_sessions: team_training_sessions
  }
end

def format_date(date_string)
  "#{date_string}T00:00:00Z"
end

def team_id(team_name)
  (@teams['data'].find { |team| team['name'] == team_name })['id']
end

def myput(str)
  print str
  $stdout.flush
end

# rubocop:disable Metrics/AbcSize
def team_training_sessions
  data = paginate_all_data(url: "teams/#{@team_id}/training_sessions")
  idx = 0
  data.map do |entry|
    idx += 1
    puts "[#{Time.new.strftime('%k:%M')}] team #{@team_name} #{idx}/#{data.size}."
    entry.merge!(parse_json_from_api("teams/training_sessions/#{entry['id']}")['data'])
    entry['participants'].each do |participant|
      @player_ids << participant['player_id'] unless @player_ids.include?(participant['player_id'])
      augment_participant_data(participant)
    end
    entry
  end
end
# rubocop:enable Metrics/AbcSize

def augment_participant_data(participant)
  participant['possible_player_matches'] = []
  participant['possible_player_matches'] += @player_id_mapping[participant['player_id']] || []
  # No longer map by shirt number since we have players from all teams here now.
  # participant['possible_player_matches'] += @player_number_mapping[participant['player_number']] || []
  participant['possible_player_matches'].uniq!
  participant['player_session'] = parse_json_from_api(
    "training_sessions/#{participant['player_session_id']}"
  )['data']
  participant['player_session_trimmed'] = parse_json_from_api(
    "training_sessions/#{participant['player_session_id']}/session_summary"
  )['data']
end

def team_details
  parse_json_from_api("teams/#{@team_id}")['data']
end
