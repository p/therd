github = require 'github'
config = require 'config'
builder = require './builder'

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

exports.explode_scope = (scope)->
  dds = ['nodb', 'postgres', 'mysql', 'mysqli', 'sqlite']
  confs = ['unit', 'functional', 'slow', 'update30']
  globals = ['check', 'merge31']
  exploded = []
  for dd in dds
    if dd in scope
      for conf in confs
        if conf in scope
          exploded.push "#{conf}-#{dd}"
  for global in globals
    if global in scope
      exploded.push global
  exploded

exports.explode_scope2 = (scope)->
  dds = ['nodb', 'postgres', 'mysql', 'mysqli', 'sqlite']
  confs = ['unit', 'functional', 'slow']
  exploded = []
  for dd in dds
    if dd in scope
      for conf in confs
        if conf in scope
          exploded.push [conf, dd]
  exploded

class PhpbbBuild extends builder.Build

exports.PhpbbBuild = PhpbbBuild
