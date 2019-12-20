# frozen_string_literal: true

require 'rubygems'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'github_api/v4/client'
require './helpers/query_helpers.rb'

require 'pry'

config_file 'config/config.yml'
helpers QueryHelper

post '/' do
  event = request.env['HTTP_X_GITHUB_EVENT']
  unless event == 'pull_request'
    msg = { message: 'event is not pull_request.' }
    json msg
    return
  end

  payload = JSON.parse(params['payload'])

  if payload['action'] == 'opened'
    pr_number = payload['number']
    owner, repo = payload['repository']['full_name'].split('/')

    change_files = retrieve_files_from_pr(pr_number: pr_number, owner: owner, repo: repo)

    # extract changes files.
    labels = settings.labels
    targets = {}
    labels.each_key do |label|
      regex = Regexp.new(labels[label])
      targets[label] = change_files.select { |v| v unless v.match(regex).nil? }
    end

    # base_branch = payload['pull_request']['base']['ref']

    puts targets

  else
    msg = { message: 'action is not opened.' }
    json msg
    return
  end
end
