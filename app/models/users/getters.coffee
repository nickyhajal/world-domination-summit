# SS - User Model

Q = require('q')

##

[Ticket, Tickets] = require '../tickets'
[Answer, Answers] = require '../answers'
[UserInterest, UserInterests] = require '../user_interests'
[Connection, Connections] = require '../connections'
[Capability, Capabilities] = require '../capabilities'
[FeedLike, FeedLikes] = require '../feed_likes'
[Feed, Feeds] = require '../feeds'
[EventRsvp, EventRsvps] = require '../event_rsvps'

getters = 

  getPic: ->
    pic = @get('pic')
    unless pic.indexOf('http') > -1
      pic = 'http://worlddominationsummit.com'+pic
    return pic
    
  getUrl: (text = false, clss = false, id = false) ->
    user_name = @get('user_name')
    clss = if clss then ' class="'+clss+'"' else ''
    id = if id then ' id="'+id+'"' else ''
    if user_name.length isnt 32
      url = '/~'+user_name
    else
      url = '/slowpoke'
    href = 'http://'+process.dmn+url
    text = if text then text else href
    return '< href="'+href+'"'+clss+id+'>'+text+'</a>'

  # Distance from PDX
  getDistanceFromPDX: (units = 'mi', opts = {}) ->
    distance = @get('distance')
    if unit is 'km'
      out = (distance * 1.60934 ) + ' km'
    else
      out = distance + ' mi'
    return Math.ceil(out)

  getAnswers: ->
    dfr = Q.defer()
    Answers.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      @set('answers', JSON.stringify(rsp.models))
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  getCapabilities: ->
    dfr = Q.defer()
    Capabilities.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      if rsp.models.length
        @set('capabilities', rsp.models)
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  getInterests: ->
    dfr = Q.defer()
    UserInterests.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      interests = []
      for interest in rsp.models
        interests.push interest.get('interest_id')
      @set('interests', JSON.stringify(interests))
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  getConnections: ->
    dfr = Q.defer()
    Connections.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (connections) =>
      connected_ids = []
      for connection in connections.models
        connected_ids.push connection.get('to_id')
      @set
        connections: connections
        connected_ids: connected_ids
      dfr.resolve(this)
    , (err) ->
      console.error(err)
    return dfr.promise

  getFeedLikes: ->
    dfr = Q.defer()
    FeedLikes.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (likes) =>
      like_ids = []
      for like in likes.models
        like_ids.push like.get('feed_id')
      @set
        feed_likes: like_ids
      dfr.resolve(this)
    , (err) ->
      console.error(err)
    return dfr.promise

  getAllTickets: ->
    dfr = Q.defer()
    Tickets.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rows) =>
      @set('tickets', rows.models)
      dfr.resolve this
    , (err) ->
      console.error(err)
    return dfr.promise

  getRsvps: ->
    dfr = Q.defer()
    EventRsvps.forge()
    .query('where', 'user_id', @get('user_id'))
    .fetch()
    .then (rsp) =>
      rsvps = []
      for rsvp in rsp.models
        rsvps.push rsvp.get('event_id')
      @set('rsvps', rsvps)
      dfr.resolve(@)
    return dfr.promise

  getLocationString: ->
    address = @get('city')+', '
    if (@get('country') is 'US' or @get('country') is 'GB') and @get('region')?
      address += @get('region')
    unless (@get('country') is 'US' or @get('country') is 'GB')
      if countries[@get('country')]?
        address += countries[@get('country')].name
    return address

module.exports = getters
