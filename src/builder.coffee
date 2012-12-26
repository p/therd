assert = require 'assert'
async = require 'async'
child_process = require 'child_process'
config = require 'config'
memorystream = require 'memorystream'
shellwords = require 'shellwords'
db = require './db'

d = console.log

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
        if self.exit_code == 0
          err = null
        else
          err = new Error "Command finished with exit code #{self.exit_code}"
        callback err
  
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

exports.Build = Build
