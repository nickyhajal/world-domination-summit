Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')
async = require('async')

[Quote, Quotes] = require('./speaker_quotes')

Speaker = Shelf.Model.extend
  tableName: 'speakers'
  idAttribute: 'speaker_id'
  permittedAttributes: [
    'speaker_id','display_name','display_avatar','descr','year','userid','type'
  ]
Speakers = Shelf.Collection.extend
  model: Speaker
  getByType: ->
    dfr = Q.defer()
    _Speakers = Speakers.forge()
    _Speakers.fetch()
    .then (rsp) ->
      bytype = {}
      async.each rsp.models, (speaker, cb) ->
        Quotes.forge()
        .query('where', 'speaker_id', speaker.get('speaker_id'))
        .fetch()
        .then (rsp) ->
          quotes = []
          (quotes.push(q.get('quote'))) for q in rsp.models
          speaker.set
            quotes: quotes
          unless bytype[speaker.get('type')]?
            bytype[speaker.get('type')] = []
          bytype[speaker.get('type')].push speaker.attributes
          cb()
      , ->
        dfr.resolve(bytype)
    return dfr.promise

module.exports = [Speaker, Speakers]