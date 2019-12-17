# frozen_string_literal: true

require 'rubygems'
require 'sinatra'
require 'sinatra/json'
require 'github_api/v4/client'

def list_query(options)
  <<~QUERY
    {
      repository(owner: "#{options[:owner]}", name: "#{options[:repo]}") {
        pullRequest(number: #{options[:pr_number]}) {
          files(first: #{options[:per_page]}, after: "#{options[:endCursor]}") {
            pageInfo {
              endCursor
              startCursor
            }
            edges {
              node {
                path
              }
            }
          }
        }
      }
    }
  QUERY
end

def init_query(options)
  <<~TOTAL_QUERY
    {
      repository(owner: "#{options[:owner]}", name: "#{options[:repo]}") {
        pullRequest(number: #{options[:pr_number]}) {
          files(first: 1) {
            totalCount
            pageInfo {
              endCursor
              startCursor
            }
            edges {
              node {
                path
              }
            }
          }
        }
      }
    }
  TOTAL_QUERY
end

def exec_query(query)
    data = github_client.graphql(query: query)

    endCursor = data['data']['repository']['pullRequest']['files']['pageInfo']['endCursor']

    files = []

    data['data']['repository']['pullRequest']['files']['edges'].each do |edge|
      files << edge['node']['path']
    end
    [endCursor, files]
end

def github_client
  GithubApi::V4::Client.new(ENV['GITHUB_ACCESS_TOKEN'])
end

post '/' do
  event = request.env['X-GitHub-Event']
  unless event == 'pull_request'
    json {}
    return
  end

  body = request.body.read
  params = JSON.parse(body)

  unless params['action'] == 'opened'
    json {}
  else
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

    totalCount = total['data']['repository']['pullRequest']['files']['totalCount']
    endCursor = total['data']['repository']['pullRequest']['files']['pageInfo']['endCursor']
    page = (totalCount / per_page.to_f).ceil

    files << total['data']['repository']['pullRequest']['files']['edges'][0]['node']['path']

    2..page.times do
      options[:endCursor] = endCursor
      endCursor, filelist = exec_query(list_query(options))
      files.concat(filelist)
    end

    # extract changes files.
    migrations = files.find {|v| v unless v.match(/db\/migrate\/*/).nil? }
    envs = files.find {|v| v unless v.match(/.env\.[development|test]/).nil? }
    onetimes = files.find {|v| v unless v.match(/script\/onetime\/*/).nil? }

  end
end
