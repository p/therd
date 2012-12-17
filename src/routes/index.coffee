async = require 'async'
db = require '../db'
kue = require 'kue'
Hash = require 'hashish'

d = console.log
jobs = kue.createQueue()

timestamp = ()->
  date = new Date()
  (date.getTime() - 1355477197389) * 1000 + date.getMilliseconds()

exports.index = (req, res) ->
  res.render('index', { title: 'Thundering Herd' });

exports.test_pr = (req, res)->
  id = 'pr-' + req.body.pr + '-' + timestamp()
  if req.body.run
    scope = new Hash req.body.run
    scope = scope.keys
    doc = {status: 'pending', scope: scope}
    async.series [
      (callback)->
        db.soft_put_build id, doc, callback
      (callback)->
        job = jobs.create 'build', {
          title: "build #{id}"
          build_id: id
        }
        job.save()
        callback null, null
    ], (err, result)->
      if err
        # ignore missing doc, fail on other errors
        res.send 500, JSON.stringify(err)
      else
        res.redirect 'status/' + id
  else
    res.send 422, 'Please set a scope'

exports.build = (req, res)->
  build = req.params.build
  db.build build, (err, doc)->
    if err and err.error == 'not_found'
      doc = {status: 'missing'}
    res.render 'build', {
      build: build, title: 'Build ' + build,
      state: doc,
    }
