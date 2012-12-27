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

class ChainGangQueue

cls_map = {
  kue: KueQueue
  'chain-gang': ChainGangQueue
  # special
  default: KueQueue
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
