Q = require('q')
request = require('request')
Twit = require('twit')

##

[TwitterLogin, TwitterLogins] = require '../twitter_logins'

twit =
  getTwit: ->
    dfr = Q.defer()
    TwitterLogin.forge
      user_id: @get('user_id')
    .fetch()
    .then (twitter_login) ->
      twit = new Twit
        consumer_key: process.env.TWIT_KEY
        consumer_secret: process.env.TWIT_SEC
        access_token: twitter_login.get('token')
        access_token_secret: twitter_login.get('secret')
      dfr.resolve(twit)
    return dfr.promise

  sendTweet: (tweet) ->
    dfr = Q.defer()
    @getTwit()
    .then (twit) ->
      twit.post 'statuses/update',
        status: tweet, (err, reply) ->
          dfr.resolve(err, reply)
    return dfr.promise

  follow: (screen_name, cb) ->
    dfr = Q.defer()
    @getTwit (twit) ->
      twit.post 'friendships/create',
        screen_name: screen_name, (err, reply) ->
          dfr.resolve(err, reply)
    return dfr.promise

  isFollowing: (screen_name, cb) ->
    dfr = Q.defer()
    @getTwit (twit) =>
      twit.get 'friendships/exists',
        screen_name_a: @twitter
        screen_name_b: screen_name
        , (err, reply) ->
          dfr.resolve(err, reply)
    return dfr.promise



module.exports = twit
