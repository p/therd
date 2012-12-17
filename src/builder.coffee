child_process = require 'child_process'
db = require './db'

d = console.log

exports.start = (build_id, callback)->
  new Build(build_id).execute()
  callback null, {}

exports.process = (build_id, callback)->
  new Build(build_id).execute callback

class Build
  constructor: (build_id)->
    @build_id = build_id
    @state = {}
  
  execute: (callback)->
    console.log 'starting build', this.build_id
    options = {
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    }
    p = child_process.spawn 'ls', ['-l']
    self = this
    p.stdout.setEncoding('utf8')
    p.stdout.on 'data', (data, callbakc)->
      self.add_output(data, callback)
    p.stderr.setEncoding('utf8')
    p.stderr.on 'data', (data, callback)->
      self.add_output(data, callback)
    p.on 'exit', (code)->
      console.log "build #{self.build_id} exited with #{code}"
      self.state.status = 'finished'
      self.save_state ()->
        callback(null)
  
  add_output: (output, callback)->
    @state.output = '' unless @state.output?
    @state.output += output
    this.save_state(callback)
  
  save_state: (callback)->
    db.update_build this.build_id, @state, (err, result)->
      if err
        console.warn "Error adding output", err
      # do not propagate errors
      callback null
