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
        Shelf.validator.check(password, "Make your password at least 8 characters so your journals are nice and safe.").len(8)
    catch error
        return whn.reject(error)
    return whn.resolve()

User = Shelf.Model.extend
  tableName: 'users'
  permittedAttributes: [
    'userid', 'email', 'first_name', 'last_name', 'created'
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

  getDuos: ->
    deferred = Q.defer()
    _Duos = Duos.forge()
    query = _Duos.query()
    _Duos
    .query('where', 'creatorid', '=', @get('userid'))
    .query('orWhere', 'acceptorid', '=', @get('userid'))
    .fetch()
    .then (rows) =>
      if rows.models.length
        getMeta = (duos, inx = 0, dfr = false) =>
          if not dfr
            dfr = Q.defer()
          if duos[inx]?
            duos[inx].getMeta(this)
            .then (duo) ->
              duos[inx] = duo
              inx += 1
              getMeta(duos, inx, dfr)
          else
            dfr.resolve duos
          if inx is 0
            return dfr.promise
        getMeta(rows.models)
        .then (duos) =>
          @set
            duos: duos
          deferred.resolve(this)
      else
        @set
          duos: []
        deferred.resolve(this)
    return deferred.promise

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