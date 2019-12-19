# frozen_string_literal: true

require 'rubygems'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'github_api/v4/client'

post '/' do
  event = request.env['X-GitHub-Event']
  unless event == 'pull_request'
    json {}
    return
  end

  body = request.body.read
  params = JSON.parse(body)

  if params['action'] == 'opened'
    per_page = 100

    pr_number = params['issue']['number']
    repo_full_name = params['repository']['full_name']
    owner, repo = repo_full_name.split('/')

    options = {
      pr_number: pr_number,
      per_page: per_page,
      owner: owner,
      repo: repo
    }

    files = []

    total = github_client.graphql(query: init_query(options))

    total_count = total['data']['repository']['pullRequest']['files']['totalCount']
    end_cursor = total['data']['repository']['pullRequest']['files']['pageInfo']['endCursor']
    page = (total_count / per_page.to_f).ceil

    files << total['data']['repository']['pullRequest']['files']['edges'][0]['node']['path']

    i = 0
    while i < page
      options[:endCursor] = end_cursor
      end_cursor, filelist = exec_query(list_query(options))
      files.concat(filelist)
      i += 1
    end

    # extract changes files.
    _migrations = files.find { |v| v unless v.match(%r{db/migrate/*}).nil? }
    _envs = files.find { |v| v unless v.match(/.env\.[development|test]/).nil? }
    _onetimes = files.find { |v| v unless v.match(%r{script/onetime/*}).nil? }

  else
    json {}
  end
end
