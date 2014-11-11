# Configuration
config = (app, express, RedisStore, mysql) ->
	app.configure ->
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
		app.use(express.cookieParser())
		app.use express.session
			secret: process.env.SESS_SEC
			store: new RedisStore
			cookie:{maxAge:10000000000}
		app.use(express.bodyParser({uploadDir:'/tmp_uploads', keepExtensions: true}))
		app.use(express.methodOverride())
		app.use require('connect-assets')(
			src: 'app/assets'
		)
		app.use(app.router)
		app.use(express.static(__dirname + '/public'))
		app.set('port', process.env.PORT)
	app.configure 'development', ->
		app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
		app.set 'db',
            client: 'mysql'
            connection:
            	host: process.env.DB_HOST
            	user: process.env.DB_USER
            	password: process.env.DB_PW
            	database: process.env.DB
            	charset: 'utf8'
            debug: false 

	app.configure 'production', ->
		app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
		app.set 'db',
            client: 'mysql'
            connection:
            	host: process.env.DB_HOST
            	user: process.env.DB_USER
            	password: process.env.DB_PW
            	database: process.env.DB
            	charset: 'utf8'
            debug: false 
module.exports = config
