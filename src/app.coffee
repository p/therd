express = require('express')
routes = require('./routes')
http = require('http')
path = require('path')

db = require './db'
db.initialize()

app = express()

app.configure(() ->
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/../views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  #app.use(require('stylus').middleware(__dirname + '/public'));
  app.use(express.static(path.join(__dirname, 'public')));
  app.use(require('connect-assets')());
);

app.configure('development', ()->
  app.use(express.errorHandler());
);

app.get('/', routes.index)
app.post('/pr', routes.test_pr)
app.get('/status/:build', routes.build)

http.createServer(app).listen(app.get('port'), ()->
  console.log("Express server listening on port " + app.get('port'));
);
