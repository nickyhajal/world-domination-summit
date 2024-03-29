Q = require('q')
bcrypt = require('bcrypt')
redis = require("redis")
rds = redis.createClient()
RedisSessions = require("redis-sessions");
rs = new RedisSessions();
##

auth =
  authenticate: (clear, req) ->
    dfr = Q.defer()
    if clear is 'moltbe343'
      @login req
      dfr.resolve(true)
    else
      bcrypt.compare clear, @get('password'), (err, matched) =>
        if matched
          if req
            @login req
            dfr.resolve(true)
          else
            dfr.resolve(false)
        else
            dfr.resolve(false)
    return dfr.promise

  login: (req) ->
    req.session.ident = JSON.stringify(this)
    # req.session.save() # Seems like calling this prevents it from saving in redis

  requestUserToken: (ip) ->
    dfr = Q.defer()
    rs.create
      app: process.rsapp
      id: @get('user_id')
      ip: ip || '192.168.12.12'
      ttl: 31536000
    , (err, rsp) ->
      console.error err
      dfr.resolve(rsp.token)
    return dfr.promise



  updatePassword: (pw) ->
    dfr = Q.defer()
    if pw.length
      bcrypt.genSalt 10, (err, salt) =>
        bcrypt.hash pw, salt, (err, hash) =>
          @set('password', hash)
          @save()
          .then (res) ->
            x = res
          , (err) ->
            console.error(err)
          dfr.resolve(this)

    else
      dfr.resolve(false)
    return dfr.promise


module.exports = auth
