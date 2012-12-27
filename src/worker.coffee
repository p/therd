kue = require 'kue'
tools = require './tools'
queue = require './queue'

d = console.log

# http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb
process.on 'uncaughtException', (err)->
  console.warn "Uncaught exception:", err.stack
  process.exit 10

queue.queue().pop_loop (job_data, callback)->
  console.log "processing #{job_data.build_id}"
  tools.process_build job_data.build_id, callback
