# frozen_string_literal: true

require 'rubygems'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'github_api/v4/client'
require 'octokit'
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
    full_repo = payload['repository']['full_name']
    owner, repo = full_repo.split('/')

    change_files = retrieve_files_from_pr(pr_number: pr_number, owner: owner, repo: repo)

    # extract changes files.
    labels = settings.labels
    targets = {}
    labels.each_key do |label|
      regex = Regexp.new(labels[label])
      targets[label] = change_files.select { |v| v unless v.match(regex).nil? }
    end

    # add labels, comments
    octokit = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])

    labels = targets.select { |k, v| k unless v.empty? }.keys
    comments = targets.select { |k, v| k unless v.empty? }.values

    octokit.add_labels_to_an_issue(full_repo, pr_number, labels) unless labels.empty?
    octokit.add_comment(full_repo, pr_number, comments.join("\n")) unless comments.empty?
  else
    msg = { message: 'action is not opened.' }
    json msg
    return
  end
end
