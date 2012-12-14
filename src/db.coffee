couchdb = require 'couchdb-api'
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
