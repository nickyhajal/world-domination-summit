# Configuration
config = (app, express, RedisStore, mysql) ->
	app.configure ->
		app.set('views', __dirname + '/views')
		app.set('view engine', 'jade')
		app.set('view options', { pretty: true });
		app.set('twitter_consumer_key', 'rk0akB9FIpVVpdayafKD6w')
		app.set('twitter_consumer_secret', 'rRDwE07S70OFqeCKrQDiwqjbCrHLN1sTslznZis')
		app.set('uploadDir', '/tmp')
		app.set 'db', 
            client: 'mysql'
            connection:
            	host: 'localhost'
            	user: 'letsduo'
            	password: 'CeAMreCOAeRE299fm19AEcmAOeSa9sm'
            	database: 'letsduo'
            	charset: 'utf8'
            debug: true
		app.set 'mail', 
			username: 'c5cc1518-87e4-4313-afc5-9a298ac033c7'
			apiKey: 'c5cc1518-87e4-4313-afc5-9a298ac033c7'

		app.use(express.cookieParser())
		app.use(express.session(
			secret: 'SOcmAO239SCM01cm10cmAO2aoiesnrtoamOSEMCOemscoaesmc'
			store: new RedisStore
		))
		app.use(express.bodyParser({uploadDir:'/tmp_uploads', keepExtensions: true}))
		app.use(express.methodOverride())
		app.use(require('connect-assets')());
		app.use(app.router)
		app.use(express.static(__dirname + '/public'));

	

	app.configure('development', ->
		app.set('port', 2222);
		app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
	);

	app.configure('test', ->
		app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
		app.set('port', 2222);
	);

	app.configure('production', ->
		app.set('port', 2222);
		app.use(express.errorHandler());
	);
module.exports = config
