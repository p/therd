async = require 'async'
Hash = require 'hashish'
config = require 'config'
fsdocs = require '../deps/fsdocs'

d = console.log
docs = new fsdocs.FSDocs(config.app.data_path)

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
  #d "Adding build #{id}"
  async.waterfall [
    (callback)->
      # attributes
      #if typeof attrs != Object
        #console.log attrs, id, typeof attrs
      docs.put 'build-' + id, attrs, callback
    (ok, callback)->
      # index read
      docs.get 'builds', callback
    (document, callback)->
      document = document || {}
      document.builds = document.builds || []
      # index update
      document.builds.push id
      # index write
      # XXX implement conflict resolution
      #if typeof document != object
        #console.log document, typeof document, 11
      docs.put 'builds', document, callback
  ], (err, ok)->
    if err
      console.warn(err.message)
    callback err, ok

exports.update_build = (id, attrs, callback)->
  #d "Updating build #{id}"
  key = 'build-' + id
  async.waterfall [
    (callback)->
      # read state - assume it exists
      docs.get key, callback
    (document, callback)->
      state = document or {}
      state = new Hash(state)
      state.update(attrs)
      state.tap (raw)->
        state = raw
      # write state
      docs.put key, state, (err, ok)->
        callback err, ok
  ], (err, ok)->
    if err
      console.warn "Error updating build #{id}", err.message
    callback err, ok

exports.update_build_sync = (id, attrs)->
  #d "Updating build #{id} synchronously"
  key = 'build-' + id
  # read state - assume it exists
  state = docs.getSync key or {}
  state = new Hash(state)
  state.update(attrs)
  state.tap (raw)->
    state = raw
  # write state
  ok = docs.putSync key, state
  unless ok
    doc = docs.getSync key
    state = combine doc, attrs
    ok = docs.putSync key, state
    unless ok
      throw 'Save failed twice'

combine = (base, cur)->
  version = base._version
  hash = new Hash(base)
  hash.update(cur)
  hash.tap (raw)->
    cur = raw
  if version
    cur._version = version + 1
  cur
