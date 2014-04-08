###
# This is the main page that all is routed through
# actual routing happens by Backbone.js
###
jade = require('jade')
redis = require("redis")
rds = redis.createClient()
fs = require('fs')
_ = require('underscore')
execFile = require('child_process').execFile;
routes = (app) ->
	

	findContent '_content'


module.exports = routes
