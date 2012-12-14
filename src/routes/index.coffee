db = require '../db'
async = require 'async'

timestamp = ()->
  date = new Date()
  (date.getTime() - 1355477197389) * 1000 + date.getMilliseconds()

exports.index = (req, res) ->
  res.render('index', { title: 'Express' });

exports.test_pr = (req, res)->
  id = 'pr-' + req.body.pr + '-' + timestamp()
  
  doc = db.doc(id)
  async.series [
    #(callback)->
      # attributes
      #doc.get callback
    (callback)->
      # attributes
      doc.body.status = 'pending'
      doc.save callback
    (callback)->
      # index
      doc = db.doc 'builds'
      doc.get (err, response)->
        if !response? and err.error != 'not_found'
          # ignore missing doc, fail on other errors
          res.send 500, JSON.stringify(err)
      doc.body = {} unless doc.body?
      doc.body[id] = id
      doc.save callback
    ],
    (err, response)->
      if err
        console.log err
        res.send 500, JSON.stringify(err)
      else
        res.redirect 'status/' + id

exports.build = (req, res)->
  build = req.params.build
  doc = db.doc build
  doc.get (err, response)->
    if !response? and err.error == 'not_found'
      status = 'missing'
    else
      status = response.status
    res.render('build', {build: build, status: status, title: 'Build ' + build})
