async = require 'async'
fsdocs = require '../deps/fsdocs'
Hash = require 'hashish'

d = console.log
docs = new fsdocs.FSDocs(__dirname + '/../data')

#server.info (err,response)->
  #console.log response


exports.initialize = ()->
  #db.info (err, response)->
    #if !response? and err.error == 'not_found'
      #console.log 'Database does not exist, creating'
      #db.create (err, response)->
        #console.log response
    #console.log err, response

exports.build = (id, callback)->
  docs.get 'build-' + id, callback

exports.soft_put_build = (id, attrs, callback)->
  async.series [
    (callback)->
      # attributes
      #if typeof attrs != Object
        #console.log attrs, id, typeof attrs
      d attrs
      docs.put 'build-' + id, attrs, callback
    (callback)->
      # index read
      docs.get 'builds', (err, document)->
        if err and err.code != 'ENOENT'
          callback err, document
        else
          if err
            # no file
            document = {builds:[]}
          # index update
          document.builds.push id
          # index write
          # XXX implement conflict resolution
          #if typeof document != object
            #console.log document, typeof document, 11
          d document
          docs.put 'builds', document, callback
  ], (err, objects)->
    if err
      console.warn(err.message)
    callback err, objects

exports.update_build = (id, attrs, callback)->
  #console.log attrs, typeof attrs
  key = 'build-' + id
  state = null
  async.series [
    (callback)->
      # read state - assume it exists
      docs.get key, (err, document)->
        unless err
          state = document.state or {}
        callback err, document
    (callback)->
      state = new Hash(state).update(attrs)
      # write state
      #for key in attrs
        #state[key] = attrs[key]
      #if typeof state != Object
        #console.log 12, state, typeof state
      #d state, attrs
      docs.put key, state, callback
  ], (err, objects)->
    if err
      console.warn(err.message)
    callback err, objects