assert = require 'assert'
path = require 'path'
async = require 'async'
child_process = require 'child_process'
config = require 'config'
memorystream = require 'memorystream'
shellwords = require 'shellwords'
db = require './db'
phpbb = require './phpbb'

d = console.log

exports.start = (build_id, callback)->
  new Build(build_id).execute()
  callback null, {}

exports.process = (build_id, callback)->
  new Build(build_id).execute callback

explode_scope = (scope)->
  dds = ['postgres', 'mysql', 'mysqli', 'sqlite']
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

class Build
  constructor: (build_id)->
    @build_id = build_id
  
  fetch_state: (callback)->
    assert callback
    self = this
    db.build @build_id, (err, doc)->
      unless err
        self.state = doc
      callback(err)
  
  execute: (callback)->
    assert callback
    console.log 'starting build', @build_id
    self = this
    @fetch_state (err)->
      if err
        self.fail err, callback
      else
        self.state.output = ''
        try
          self.do_execute (err)->
            if err
              self.fail err, callback
            else
              callback err
        catch err
          self.fail err, callback
  
  do_execute: (callback)->
    assert callback
    self = this
    #self.exploded_scope = explode_scope self.state.scope
    async.waterfall [
      (done)->
        phpbb.fetch_pr_meta self.state.pr_msg, done
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
  
  build_exec: (cmd, callback)->
    self = this
    options = {
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    }
    args = ['-iu', config.app.build_user].concat cmd...
    p = child_process.spawn 'sudo', args
    ms = new memorystream
    p_code = null
    p_signal = null
    #p.stdout.setEncoding('utf8')
    p.stdout.pipe(ms)
    #p.stdout.on 'data', (data)->
      #self.add_output data
    #p.stderr.setEncoding('utf8')
    p.stderr.pipe(ms)
    #p.stderr.on 'data', (data)->
      #assert callback
      #self.add_output(data)
    ms.setEncoding('utf8')
    ms.on 'data', (data)->
      assert callback
      if config.app.print_output and process.stdout.isTTY
       console.log data
      self.add_output(data)
    p.on 'exit', (code, signal)->
      self.exit_code = code
      p_signal = signal
    p.on 'close', ()->
      if self.exit_code == 0
        self.state.status = 'finished'
      else
        self.state.status = 'failed'
      self.save_state ()->
        callback(null)
  
  build_exec_in_dir: (cmd, callback)->
    escaped_cmd = (shellwords.escape word for word in cmd).join(' ')
    escaped_dir = shellwords.escape @build_dir
    cmd = "cd #{escaped_dir} && #{escaped_cmd}"
    cmd = ['sh', '-c', cmd]
    @build_exec cmd, callback
  
  # callback may be null
  add_output: (output, callback)->
    @state.output = '' unless @state.output?
    @state.output += output
    this.save_state(callback)
  
  # callback may be null in which sync path will be used
  save_state: (callback)->
    if callback
      db.update_build this.build_id, @state, (err, result)->
        if err
          console.warn "Error adding output", err
        # do not propagate errors
        callback null
    else
      db.update_build_sync this.build_id, @state
  
  fail: (err, callback)->
    d err, 'failing'
    @state.status = 'failed'
    @state.output += err.toString()
    @save_state (errnull)->
      callback err

u_cmd = (cmd)->
  __dirname + '/../bin/u/' + cmd
