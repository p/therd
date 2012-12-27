fsdocs = require '../deps/fsdocs'

class FSDocsQueue
  constructor: (path)->
    @path = path
    @docs = new fsdocs.FSDocs @path
  
  create: (name, attrs)->
    new Job @docs, name, attrs
  
  process: (name, callback)->
    @fetch_one_job name, (err, attrs)=>
      next = ()=>
        @process name, callback
      if err?
        console.warn err.stack
      if !err? && attrs
        # no error and something in queue
        callback attrs, (err)=>
          if err?
            console.warn err.stack
          # look for more jobs immediately
          process.nextTick next
      else
        # error or queue empty
        setTimeout next, 1000
  
  fetch_one_job: (name, done)->
    key = "q:#{name}"
    @docs.get key, (err, doc)=>
      if err
        done err
      else
        if doc
          attrs = doc.jobs.shift()
          doc._version = doc._version + 1
          @docs.put key, doc, (err)=>
            if err
              done err
            else
              done null, attrs
        else
          # queue is empty
          done null, null

class Job
  constructor: (docs, name, attrs)->
    @docs = docs
    @name = name
    @attrs = attrs
  
  save: (done)->
    key = "q:#{@name}"
    @docs.get key, (err, doc)=>
      if err
        done err
      else
        if doc
          doc._version = doc._version + 1
          doc.jobs.push @attrs
        else
          doc = {jobs: [@attrs]}
        @docs.put key, doc, (err)->
          done err

exports.createQueue = (path)->
  new FSDocsQueue path
