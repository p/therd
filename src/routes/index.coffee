Hash = require 'hashish'
db = require '../db'
tools = require '../tools'

d = console.log

exports.index = (req, res) ->
  db.builds (err, builds)->
    build_ids = builds.builds.reverse()
    res.render('index', { title: 'Thundering Herd', build_ids: build_ids });

exports.test_pr = (req, res)->
  if req.body.run
    scope = new Hash req.body.run
    scope = scope.keys
    pr = req.body.pr
    tools.submit_test_pr pr, scope, (err, id)->
      if err
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
