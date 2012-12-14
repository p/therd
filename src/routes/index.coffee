db = require '../db'

timestamp = ()->
  date = new Date()
  (date.getTime() - 1355477197389) * 1000 + date.getMilliseconds()

exports.index = (req, res) ->
  res.render('index', { title: 'Express' });

exports.test_pr = (req, res)->
  id = 'pr-' + req.body.pr + '-' + timestamp()
  
  db.soft_put_build id, {status: 'pending'}, (err, response) ->
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
    else
      status = response.status
    res.render('build', {build: build, status: status, title: 'Build ' + build})
