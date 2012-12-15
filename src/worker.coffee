kue = require 'kue'

jobs = kue.createQueue()

jobs.process 'build', (job, done)->
  console.log "processing #{job} #{done}"
  done()
