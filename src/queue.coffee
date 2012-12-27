# frontend to kue and chain-gang

config = require 'config'

class KueQueue
  constructor: ()->
    @kue = require 'kue'
    @jobs = @kue.createQueue()
  
  push: (attrs, done)->
    job = @jobs.create 'build', attrs
    job.save()
    done null, job
  
  pop_loop: (callback)->
    @jobs.process 'build', (job, done)->
      callback job.data, done

class FSDocsQueueQueue
  constructor: ()->
    @fsdq = require './fsdocs-queue'
    @jobs = @fsdq.createQueue config.app.data_path
  
  push: (attrs, done)->
    job = @jobs.create 'build', attrs
    job.save (err)=>
      done err, job
  
  pop_loop: (callback)->
    @jobs.process 'build', (job, done)->
      callback job.data, done

cls_map = {
  kue: KueQueue
  'fsdocs-queue': FSDocsQueueQueue
  # special
  default: FSDocsQueueQueue
}

create_queue = ()->
  which = config.app.queue || 'default'
  cls = cls_map[which]
  new cls

$queue = null

exports.queue = ()->
  unless $queue?
    $queue = create_queue()
  $queue
