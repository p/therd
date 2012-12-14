async = require 'async'
mongode = require 'mongode'

conn = mongode.connect('mongo://127.0.0.1/thunder')

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
  collection = conn.collection('builds')
  collection.findOne {id: id}, callback

exports.soft_put_build = (id, attrs, callback)->
  identity = {}
  identity[id] = id
  async.series [
    (callback)->
      # attributes
      attrs.id = id
      collection = conn.collection('builds')
      collection.insert attrs, callback
  ], (err, objects)->
    if err
      console.warn(err.message)
    callback err, objects
