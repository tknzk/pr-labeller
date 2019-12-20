# frozen_string_literal: true

#
# query helper method.
#
module QueryHelper
  def github_client
    GithubApi::V4::Client.new(ENV['GITHUB_ACCESS_TOKEN'])
  end

  def retrieve_files_from_pr(pr_number:, owner:, repo:)
    per_page = 100
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

    files
  end

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

    end_cursor = data['data']['repository']['pullRequest']['files']['pageInfo']['endCursor']

    files = []

    data['data']['repository']['pullRequest']['files']['edges'].each do |edge|
      files << edge['node']['path']
    end
    [end_cursor, files]
  end
end
