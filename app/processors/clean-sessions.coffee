# We set a long expire time so users aren't logged out
# but connect-redis then leaves us with tons of sessions
# from non-logged in users that have long TTLs
#
# This will clean those up on a regular basis

redis = require("redis")
rds = redis.createClient()
shell = (app) ->
  process = ->
    rds.keys 'sess:*', (err, rsp) ->
      for sess in rsp
        check(sess)
    setTimeout ->
      process()
    , 10000
  check = (sess) ->
    rds.get sess, (err, rsp) ->
      if rsp? && rsp.indexOf('ident') == -1 && rsp.indexOf('twitter_connect') == -1
        rds.ttl sess, (err, rsp) ->
          diff = (10000000 - +rsp)
          if diff > 2000
            rds.expire sess, 0
  process()

module.exports = shell
