Q = require('q')
bcrypt = require('bcrypt')

##

auth =
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
    req.session.save()

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
