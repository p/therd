d = console.log

exports.build = ()->
  build_id = process.argv[2]
  
  if !build_id
    throw "build_id not specified"
  
  builder = require './builder'
  builder.process build_id, (err, result)->
    d err, result
