timestamp = ()->
  date = new Date()
  (date.getTime() - 1355477197389) * 1000 + date.getMilliseconds()

exports.index = (req, res) ->
  res.render('index', { title: 'Express' });

exports.test_pr = (req, res)->
  id = 'pr-' + req.body.pr + '-' + timestamp()
  res.redirect 'status/' + id
