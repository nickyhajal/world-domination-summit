# Configuration
config = (app, express, RedisStore, mysql) ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.set('view options', { pretty: true });
  app.set('flickr_pub', process.env.FLCKR_PUB)
  app.set('flickr_secret', process.env.FLCKR_SEC)
  app.set('ig_key', process.env.IG_KEY)
  app.set('ig_sec', process.env.IG_SECRET)
  app.set('twitter_consumer_key', process.env.TWIT_KEY)
  app.set('twitter_consumer_secret', process.env.TWIT_SEC)
  app.set('twitter_token', process.env.TWIT_TOKEN)
  app.set('twitter_token_secret', process.env.TWIT_TOKEN_SEC)
  app.set('eb_key', process.env.EB_KEY)
  app.set('eb_user', process.env.EB_USER)
  app.set('eb_event', process.env.EB_EVENT)
  app.set('wufoo_account', process.env.WUFOO_ACCOUNT)
  app.set('wufoo_key', process.env.WUFOO_KEY)
  app.set('wufoo_amb_form', process.env.WUFOO_AMB_FORM)
  app.set('uploadDir', '/tmp')
  # app.use(express.methodOverride())
  app.use require('connect-assets')(
    paths: ['app/assets', 'app/assets/js', 'app/assets/css']
  )
  app.use(express.static(__dirname + '/public'))
  app.set('port', process.env.PORT)

  if process.env.NODE_ENV is 'development'
    app.use (err, req, res, next) ->
      res.status(err.status || 500)
      res.render 'error',
          message: err.message,
          error: err
    app.set 'apn',
      cert: process.env.APN_CERT
      key: process.env.APN_KEY
      ca: process.env.APN_CA
    app.set 'db',
      client: 'mysql'
      connection:
        host: process.env.DB_HOST
        user: process.env.DB_USER
        password: process.env.DB_PW
        database: process.env.DB
        charset: 'utf8'
      debug: true
  else
    app.use (err, req, res, next) ->
      res.status(err.status || 500)
      res.render 'error',
          message: err.message,
          error: {}
    app.set 'apn',
      cert: process.env.APN_CERT
      key: process.env.APN_KEY
      ca: process.env.APN_CA
      production: true
    app.set 'db',
      client: 'mysql'
      connection:
        host: process.env.DB_HOST
        user: process.env.DB_USER
        password: process.env.DB_PW
        database: process.env.DB
        charset: 'utf8mb4'
      debug: false
module.exports = config
