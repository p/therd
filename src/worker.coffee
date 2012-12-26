kue = require 'kue'
tools = require './tools'

jobs = kue.createQueue()

jobs.process 'build', (job, callback)->
  console.log "processing #{job.data.build_id}"
  tools.process_build job.data.build_id, callback
