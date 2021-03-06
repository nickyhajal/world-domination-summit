Q = require('q')
request = require('request')
_ = require('underscore')
[Email, Emails] = require('../emails');

##

emails =
  sendEmail: (promo, subject, params = {}, resend = false) ->
    mailer = require('../mailer')
    user_params =
      first_name: @get('first_name')
      last_name: @get('last_name')
      name: @get('first_name')
      email: @get('email')
      hash: @get('hash')
    params = _.defaults user_params, params
    mailer.send(promo, subject, @get('email'), params)
    .then (err, rsp) =>
      log ={promo, subject, user_id: @get('user_id'), data: JSON.stringify(params)} 
      if resend
        log.resent_from = resend
      Email.forge(log).save().then()

  syncEmail: ->
    if @get('attending'+process.tkyr) is '1'
      if @get('ticket_type')?.length
        if @get('ticket_type') is 'connect'
          @addToList 'WDS '+process.tkyear+' Connect'
          @removeFromList 'WDS '+process.tkyear+' Connect', @before_save['email']
        else
          @addToList 'WDS '+process.tkyear+' Attendees'
          @removeFromList 'WDS '+process.tkyear+' Attendees', @before_save['email']
      if @get('type') is 'friend'
          @addToList 'WDS '+process.tkyear+' Friends'

  syncEmailWithTicket: ->
    if @get('attending'+process.tkyr) is '1'
      if @get('ticket_type')?.length
        if @get('ticket_type') is 'connect'
          @addToList 'WDS '+process.tkyear+' Connect'
        else
          @addToList 'WDS '+process.tkyear+' Attendees'
        @removeFromList 'WDS '+process.tkyear+' Canceled'
      if @get('type') is 'friend'
          @addToList 'WDS '+process.tkyear+' Friends'
    else
      @removeFromList 'WDS '+process.tkyear+' Attendees'
      @removeFromList 'WDS '+process.tkyear+' Connect'
      @addToList 'WDS '+process.tkyear+' Canceled'
  addToList: (list, custom = false) ->
    dfr = Q.defer()
    params =
      username: process.env.MM_USER
      api_key: process.env.MM_PW
      email: @get('email')
      first_name: @get('first_name')
      last_name: @get('last_name')
      unique_link: @get('hash')
    if custom
      for i,v of custom
        params[i] = v
    call_list =
      url: 'https://api.madmimi.com/audience_lists'
      method: 'post'
      form:
        name: list
        username: process.env.MM_USER
        api_key: process.env.MM_PW
    call_user =
      url: 'https://api.madmimi.com/audience_lists/'+list+'/add'
      method: 'post'
      form: params
    request call_list, (err, code, rsp) ->
      request call_user, (err, code, rsp) ->
        tk rsp
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
