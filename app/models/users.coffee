Shelf = require('./shelf')
Bookshelf = require('bookshelf')
whn = require('when')
nodefn = require('when/node/function')
bcrypt = require('bcrypt')
crypto = require('crypto')
_ = require('underscore')
Q = require('q')

validatePasswordLength = (password) ->
    try
        Shelf.validator.check(password, "Make your password at least 8 characters so your profile is nice and safe.").len(8)
    catch error
        return whn.reject(error)
    return whn.resolve()

User = Shelf.Model.extend
  tableName: 'attendees'
  permittedAttributes: [
    'attendeeid', 'type', 'email', 'fname', 'lname', 'attending', 'attended11', 'attending12',
    'attending13', 'attending14', 'email', 'fname', 'lname', 'hash',
    'uname', 'phone', 'mf', 'twitter', 'pic', 'address', 'city',
    'state', 'country', 'zip', 'lat', 'lon', 'distance', 'video', 'rss',
    'pub_loc', 'pub_att', 'intro2011', 'marker', 'intro', 'intro13', 'picxy', 
    'picupd', 'points13', 'points', 'lastShake', 'stamp'
  ]
  hasTimestamps: true
  initialize: ->
    this.on 'creating', this.creating, this
    this.on 'created', this.created, this

  authenticate: (clear, req) -> 
    dfr = Q.defer()
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

  creating: (e)->
    self = this
    userData = self.attributes
    return validatePasswordLength(userData.password).then( ->
      return User.forge({email: userData.email}).fetch()
    ).then((user) ->
        if (user)
          return whn.reject(new Error('That email is already registered!'));
    ).then( ->
      return nodefn.call(bcrypt.genSalt);
    ).then((salt)->
      return nodefn.call(bcrypt.hash, userData.password, salt);
    ).then((hash)->
      email_hash = crypto.createHash('md5').update(self.get('email')).digest('hex');
      self.set
        password: hash
        email_hash: email_hash 
    )
  created: (e) ->
    setTimeout =>
      @email('Welcome', "Welcome to Let's Duo!")
    , 10
  email: (email, subject, params) ->
    mailer = require('./mailer')
    user_params =
      first_name: @get('first_name')
      last_name: @get('last_name')
      email: @get('email')
    params = _.defaults user_params, params
    mailer.send(email, subject, @get('email'), params)
    .then (err, rsp) ->

Users = Shelf.Collection.extend
  model: User 
  getUser: (userid, remove_password = true) ->
    dfr = Q.defer()
    _Users = Users.forge()
    if typeof +userid is 'number'
      type = 'userid'
    else if typeof userid is 'string'
      type = 'email'
    _Users.query('where', type, '=', userid)
    .fetch()
    .then (rsp)->
      results = []
      if rsp.models?[0]?
        results = rsp.models[0]
        if remove_password
          results.password = null
      dfr.resolve(results)
    return dfr.promise

module.exports = [User, Users]