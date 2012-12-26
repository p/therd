kue = require 'kue'
tools = require './tools'

jobs = kue.createQueue()

# http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb
process.on 'uncaughtException', (err)->
  console.warn "Uncaught exception:", err
  process.exit 10

jobs.process 'build', (job, callback)->
  console.log "processing #{job.data.build_id}"
  tools.process_build job.data.build_id, callback
