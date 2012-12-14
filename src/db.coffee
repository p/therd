couchdb = require 'couchdb-api'
async = require 'async'

server = couchdb.srv()
db = server.db 'thunder'

server.info (err,response)->
  console.log response

exports.initialize = ()->
  db.info (err, response)->
    if !response? and err.error == 'not_found'
      console.log 'Database does not exist, creating'
      db.create (err, response)->
        console.log response
    console.log err, response

exports.doc = (id)->
  db.doc(id)

exports.soft_put_build = (id, attrs, callback)->
  doc = db.doc(id)
  async.series [
    #(callback)->
      # attributes
      #doc.get callback
    (callback)->
      # attributes
      # XXX overwrites rather than updates body
      doc.body = attrs
      doc.save callback
    (callback)->
      # index
      doc = db.doc 'builds'
      doc.get (err, response)->
        if !response? and err.error != 'not_found'
          callback(err, response)
      doc.body = {} unless doc.body?
      doc.body[id] = id
      doc.save callback
    ],
  callback
