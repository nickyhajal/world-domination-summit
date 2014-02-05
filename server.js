global.tk = console.log;
require('coffee-script');
require('coffee-trace');
var Bookshelf = require('bookshelf');
var Knex = require('knex');
var express = require('express');
var RedisStore = require('connect-redis')(express);
var app = module.exports = express.createServer();
require('./app/config')(app, express, RedisStore);
require('express-namespace');
process.db = app.settings.db
process.mail = app.settings.mail


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
require('./app/routes/api')(app);
require('./app/routes/index')(app);
app.listen(app.settings.port, function(){
  console.log("Express server listening on port %d in %s mode", app.settings.port, app.settings.env);
});
