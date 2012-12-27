async = require 'async'
db = require './db'
phpbb = require './phpbb'
queue = require './queue'

d = console.log

timestamp = ()->
  date = new Date()
  (date.getTime() - 1355477197389) * 1000 + date.getMilliseconds()

exports.build = ()->
  build_id = process.argv[2]
  
  if !build_id
    throw "build_id not specified"
  
  exports.process_build build_id, (err, result)->
    d err, result

exports.build = (done)->
  pr = process.argv[2]
  scope = process.argv[3].split /\s+/
  
  if !pr || !scope
    throw "build_id or scope not specified"
  
  exports.test_pr pr, scope, (err, build_id)->
    exports.process_build build_id, (err, result)->
      done err

exports.test_pr = (pr, scope, done)->
  pr_msg = phpbb.resolve_pr pr
  id = 'pr-' + pr + '-' + timestamp()
  doc = {status: 'pending', scope: scope, pr_msg: pr_msg}
  async.series [
    (callback)->
      db.soft_put_build id, doc, callback
  ], (err)->
    done err, id

exports.submit_test_pr = (pr, scope, done)->
  pr_msg = phpbb.resolve_pr pr
  id = 'pr-' + pr + '-' + timestamp()
  doc = {status: 'pending', scope: scope, pr_msg: pr_msg}
  async.series [
    (callback)->
      db.soft_put_build id, doc, callback
    (callback)->
      attrs = {
        title: "build #{id}"
        build_id: id
      }
      queue.queue().push attrs, callback
  ], (err)->
    done err, id

exports.start_build = (build_id, callback)->
  new phpbb.PhpbbBuild(build_id).execute()
  callback null, {}

exports.process_build = (build_id, callback)->
  new phpbb.PhpbbBuild(build_id).execute callback
