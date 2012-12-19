assert = require 'assert'
async = require 'async'
child_process = require 'child_process'
config = require 'config'
memorystream = require 'memorystream'
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
        callback(err)
      else
        self.state.output = ''
        self.do_execute callback
  
  do_execute: (callback)->
    assert callback
    self = this
    async.waterfall [
      (done)->
        phpbb.fetch_pr_meta self.state.pr_msg, done
      (pr_meta, done)->
        self.build_exec ['git', 'clone', pr_meta.head.repo.clone_url], done
      (done)->
        console.log "build #{self.build_id} exited with #{self.exit_code}"
    ], callback
  
  build_exec: (cmd, callback)->
    self = this
    options = {
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    }
    args = ['-u', config.app.build_user]
    args.splice args.length, 0, cmd...
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
      self.state.status = 'finished'
      self.save_state ()->
        callback(null)
  
  wip: ()->
    exploded = explode_scope self.state.scope
  
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
