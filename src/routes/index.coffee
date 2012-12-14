exports.index = (req, res) ->
  res.render('index', { title: 'Express' });

exports.test_pr = (req, res)->
  #id = pr + 
  res.redirect 'ok/' + req.body.pr
