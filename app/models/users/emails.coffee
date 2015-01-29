Q = require('q')
request = require('request')
_ = require('underscore')

##

emails =
  sendEmail: (promo, subject, params = {}) ->
    tk 'SENDEMAIL'
    tk '>>'+promo
    mailer = require('../mailer')
    user_params =
      first_name: @get('first_name')
      last_name: @get('last_name')
      name: @get('first_name')
      email: @get('email')
      hash: @get('hash')
    params = _.defaults user_params, params
    mailer.send(promo, subject, @get('email'), params)
    .then (err, rsp) ->

  syncEmail: ->
    @removeFromList 'WDS '+process.year+' Attendees', @before_save['email']
    @addToList 'WDS '+process.year+' Attendees'

  syncEmailWithTicket: ->
    if @get('attending'+process.yr) is '1'
      @addToList 'WDS '+process.year+' Attendees'
      @removeFromList 'WDS '+process.year+' Canceled'
    else
      @removeFromList 'WDS '+process.year+' Attendees'
      @addToList 'WDS '+process.year+' Canceled'

  addToList: (list) ->
    dfr = Q.defer()
    params =
      username: process.env.MM_USER
      api_key: process.env.MM_PW
      email: @get('email')
      first_name: @get('first_name')
      last_name: @get('last_name')
      unique_link: @get('hash')
    call =
      url: 'https://api.madmimi.com/audience_lists/'+list+'/add'
      method: 'post'
      form: params
    request call, (err, code, rsp) ->
      dfr.resolve(rsp)
    return dfr.promise

  removeFromList: (list, email = false) ->
    dfr = Q.defer()
    params =
      username: process.env.MM_USER
      api_key: process.env.MM_PW
      email: @get('email')
    if email
      params.email = email
    call =
      url: 'https://api.madmimi.com/audience_lists/'+list+'/remove'
      method: 'post'
      form: params
    request call, (err, code, rsp) ->
      dfr.resolve(rsp)
    return dfr.promise

module.exports = emails
