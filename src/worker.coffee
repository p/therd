kue = require 'kue'
builder = require './builder'

jobs = kue.createQueue()

jobs.process 'build', (job, callback)->
  console.log "processing #{job.data.build_id}"
  builder.process job.data.build_id, callback
