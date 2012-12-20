github = require 'github'
config = require 'config'

d = console.log
gh = new github {version: '3.0.0', timeout: config.app.network_timeout}
gh.authenticate {
  type: 'basic'
  username: config.app.github_username
  password: config.app.github_password
}

# Useful fields:
#
# head.ref
# head.repo.clone_url
# base.ref
# user.login

is_number = (v)->
  !isNaN(parseFloat(v)) && isFinite(v)

exports.resolve_pr = (pr)->
  if is_number pr
    msg = {
      user: 'phpbb'
      repo: 'phpbb3'
      number: pr
    }
  else
    throw 'This path is not implemented yet'

exports.fetch_pr_meta = (msg, done)->
  gh.pullRequests.get msg, done
