child_process = require 'child_process'
db = require './db'

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
    p = child_process.spawn 'find', ['.']
    self = this
    p.stdout.setEncoding('utf8')
    p.stdout.on 'data', (data)->
      self.add_output(data)
    p.stderr.setEncoding('utf8')
    p.stderr.on 'data', (data)->
      self.add_output(data)
    p.on 'exit', (code)->
      console.log "build #{self.build_id} exited with #{code}"
      callback(null)
  
  add_output: (output)->
    @state.output = '' unless @state.output?
    @state.output += output
    db.update_build this.build_id, {output: @state.output}, (err, result)->
      if err
        console.log err
