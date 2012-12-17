async = require 'async'
db = require '../db'
kue = require 'kue'

d = console.log
jobs = kue.createQueue()

timestamp = ()->
  date = new Date()
  (date.getTime() - 1355477197389) * 1000 + date.getMilliseconds()

exports.index = (req, res) ->
  res.render('index', { title: 'Thundering Herd' });

exports.test_pr = (req, res)->
  id = 'pr-' + req.body.pr + '-' + timestamp()
  doc = {status: 'pending'}
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

exports.build = (req, res)->
  build = req.params.build
  doc = db.build build, (err, response)->
    if err and err.error == 'not_found'
      status = 'missing'
      output = ''
    else
      status = response.status
      output = response.output
    res.render 'build', {
      build: build, status: status, title: 'Build ' + build,
      output: output,
    }
