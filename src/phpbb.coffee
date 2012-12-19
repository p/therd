github = require 'github'
config = require 'config'

d = console.log
gh = new github {version: '3.0.0'}
gh.authenticate {
  type: 'basic'
  username: config.app.github_username
  password: config.app.github_password
}

resolve_pr = (pr, done)->
  msg = {
    user: 'phpbb'
    repo: 'phpbb3'
    number: pr
  }
  gh.pullRequests.get msg, done
  #(err, data)->
    #if err
      #done err
    #else
      #meta = {
        #head_ref: data.head.ref
        #base_ref: data.base.ref
      #}
      #done null, meta
