partial = require 'partial'
async = require 'async'
path = require 'path'
assert = require 'assert'
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
  do_execute: (callback)->
    assert callback
    self = this
    async.waterfall [
      (done)->
        exports.fetch_pr_meta self.state.pr_msg, done
      (pr_meta, done)->
        self.pr_meta = pr_meta
        unless self.pr_meta.head.repo
          err = new Error 'pr had no head.repo metadata'
          done err
        else
          self.build_dir = path.join(config.app.build_root, self.build_id)
          self.build_exec ['rm', '-rf', self.build_dir], done
      (done)->
        self.build_exec ['git', 'cclone', self.pr_meta.head.repo.clone_url, self.build_dir], done
      (done)->
        # add and fetch upstream for testing merge into requested branch
        self.build_exec_in_dir [
          'git', 'remote', 'add', 'upstream', 'git://github.com/phpbb/phpbb3.git', '-f',
        ], done
      (done)->
        self.add_output "Merging into current base", done
      (done)->
        # merge into requested branch
        self.build_exec_in_dir [
          u_cmd('check-merge'), 'origin/' + self.pr_meta.head.ref, 'upstream/' + self.pr_meta.base.ref,
        ], done
      (done)->
        self.add_output 'Running tests', done
      (done)->
        self.run_tests done
      (done)->
        self.add_output "Merging into develop", done
      (done)->
        # merge into develop
        if self.pr_meta.base.ref != 'develop'
          # XXX handle prep-release branches
          self.build_exec_in_dir [
            u_cmd('check-merge-forward'), 'upstream/develop',
          ], done
        else
          done null
      (done)->
        console.log "build #{self.build_id} exited with #{self.exit_code}"
        done null
    ], callback
  
  run_tests: (done)->
    @exploded_scope = exports.explode_scope2 @state.scope
    fns = (partial(@run_dbms_test.bind(this), type, dbms) for type, dbms in @exploded_scope)
    if fns.length > 0
      async.series fns, done
    else
      console.warn 'No tests specified'
      done null
  
  # XXX what is in the third parameter?
  run_dbms_test: (type, dbms, whatsthis, done)->
    self = this
    self.build_exec_in_dir [
      u_cmd('test'), type, dbms,
    ], done

u_cmd = (cmd)->
  __dirname + '/../bin/u/' + cmd

exports.PhpbbBuild = PhpbbBuild
