assert = require 'assert'
child_process = require 'child_process'
db = require './db'

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
        self.do_execute callback
  
  do_execute: (callback)->
    assert callback
    self = this
    exploded = explode_scope self.state.scope
    options = {
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    }
    p = child_process.spawn 'echo', exploded
    p.stdout.setEncoding('utf8')
    p.stdout.on 'data', (data)->
      self.add_output data
    p.stderr.setEncoding('utf8')
    p.stderr.on 'data', (data, callback)->
      assert callback
      self.add_output(data, callback)
    p.on 'exit', (code)->
      console.log "build #{self.build_id} exited with #{code}"
      self.state.status = 'finished'
      self.save_state ()->
        callback(null)
  
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
