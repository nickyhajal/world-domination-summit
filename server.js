Error.stackTraceLimit = Infinity;
global.tk = console.log;
require('coffee-script');
require('coffee-trace');
var Bookshelf = require('bookshelf');
var express = require('express');
var session = require('express-session');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var layout = require('express-layout');
var RedisStore = require('connect-redis')(session);
var app = express();
app.use(cookieParser());
// app.use(bodyParser.json({
//   extended: true,
//   uploadDir:'/tmp_uploads',
//   keepExtensions: true
// }));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(layout());
app.set('layouts', './app/views');
app.set('layout', 'layout');
app.use(session({
  secret: process.env.SESS_SEC,
  store: new RedisStore,
  cookie:{ maxAge: 10000000000 },
  resave: false,
  saveUninitialized: false,
}));
var apn = require('apn');
var gcm = require('node-gcm');
require('./app/config')(app, express, RedisStore);
if (process.env.DIR !== undefined) {
	process.chdir(process.env.DIR);
}
console.log(app.settings.db);
process.knex = require('knex')(app.settings.db);
db = process.db = app.settings.db;
process.mail = app.settings.mail;
process.year = '2017';
process.yr = '17';
process.lastYear = '2016';
process.dmn = process.env.DOMAIN;
process.rsapp = 'mobile_logins';
process.APN = new apn.Connection(app.settings.apn);
process.gcmSender = new gcm.Sender(process.env.GCM_KEY);
process.fire = require("firebase-admin");
process.fire.initializeApp({
  credential: process.fire.credential.cert(process.env.FIREBASE_CONF),
  databaseURL: process.env.FIREBASE_URL,
  databaseAuthVariableOverride: {
    uid: 'wdsfm-ak89aoemakqysbk48zcbp73aiaoe381c'
  }
});

//require('./app/processors/wufoo')(app)
//require('./app/processors/meetup_suggestions')(app)
	// require('./app/processors/eventbrite_dup_check')(app)
if (process.env.NODE_ENV === 'production' && process.env.PORT == '7676') {
	// require('./app/processors/academies')(app);
	// require('./app/processors/clean-sessions')(app);
	// require('./app/processors/eventbrite')(app);
	// require('./app/processors/content-grabber')(app);
	// require('./app/processors/third-party-feeds')(app);
	// setTimeout(function(){
	// 	// Notifications = require('./app/models/notifications')[1];
	// 	// Notifications.prototype.process();
	// }, 500);
}

// Uncomment to update twitter avatars
//require('./app/processors/twitter_avs')(app)


// Twitter OAuth
var OAuth= require('oauth').OAuth;
var oa = new OAuth(
	"https://api.twitter.com/oauth/request_token",
	"https://api.twitter.com/oauth/access_token",
	app.settings.twitter_consumer_key,
	app.settings.twitter_consumer_secret,
	"1.0",
	app.settings.twitter_callback,
	"HMAC-SHA1"
);
app.set('oa', oa);
require('./app/views/helpers')(app);
require('./app/routes/registration')(app);
require('./app/routes/api')(app);
require('./app/routes/upload')(app);
require('./app/routes/index')(app);
require('./app/routes/git-hook')(app);
app.listen(app.settings.port, function(){
  console.log("Express server listening on port %d in %s mode", app.settings.port, app.settings.env);
});

