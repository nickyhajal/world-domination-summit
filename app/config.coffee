# Configuration
config = (app, express, RedisStore, mysql) ->
	app.configure ->
		app.set('views', __dirname + '/views')
		app.set('view engine', 'jade')
		app.set('view options', { pretty: true });
		app.set('twitter_consumer_key', 'rk0akB9FIpVVpdayafKD6w')
		app.set('twitter_consumer_secret', 'rRDwE07S70OFqeCKrQDiwqjbCrHLN1sTslznZis')
		app.set('uploadDir', '/tmp')
		app.set 'mail', 
			username: 'c5cc1518-87e4-4313-afc5-9a298ac033c7'
			apiKey: 'c5cc1518-87e4-4313-afc5-9a298ac033c7'

		app.use(express.cookieParser())
		app.use express.session
			secret: 'SOcmAO239SCM01cm10cmAO2aoiesnrtoamOSEMCOemscoaesmc'
			store: new RedisStore
		app.use(express.bodyParser({uploadDir:'/tmp_uploads', keepExtensions: true}))
		app.use(express.methodOverride())
		app.use require('connect-assets')(
			src: 'app/assets'
			build: false
		)
		app.use(app.router)
		app.use(express.static(__dirname + '/public'));

	

	app.configure 'development', ->
		app.set('port', 6767);
		app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
		app.set 'db', 
            client: 'mysql'
            connection:
            	host: 'localhost'
            	user: 'root'
            	password: 'a'
            	database: 'wdsfm13'
            	charset: 'utf8'
            debug: false

	app.configure 'test', ->
		app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
		app.set('port', 2222);

	app.configure 'production', ->
		app.set('port', 7676);
		app.use(express.errorHandler());
		app.set 'db', 
            client: 'mysql'
            connection:
            	host: 'mysql'
            	user: 'chrisgui_wdsfm'
            	password: 'eAEcmAocesMAEckeSAOeckAlcska11819A'
            	database: 'chrisgui_wds'
            	charset: 'utf8'
            debug: true

module.exports = config
