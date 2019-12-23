# pr-labeller
A GitHub Pull Request Labeller.


```
$ bundle install
```

Run

```
$ bundle exec shotgun
```

## ENV

```.env
GITHUB_ACCESS_TOKEN=SOME-GITHUB-ACCESS-TOKEN
GITHUB_WEBHOOK_SECRET=SOME-GITHUB-WEBHOOK-SECRET
```


## Configuration
- key: pull reqeust label
- val: filename regex

```config/config.yml
labels:
  migration: '/db/migrations/*'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tknzk/pr-labeller. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the PRLabeller project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tknzk/pr-labeller/blob/master/CODE_OF_CONDUCT.md)
