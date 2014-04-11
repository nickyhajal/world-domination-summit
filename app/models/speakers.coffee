Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')

Speaker = Shelf.Model.extend
  tableName: 'speakers'
  permittedAttributes: [
    'speakerid','display_name','display_avatar','descr','year','userid'
  ]
Speakers = Shelf.Collection.extend
  model: Speaker
  getByType: ->
    dfr = Q.defer()
    _Speakers = Speakers.forge()
    _Speakers.fetch()
    .then (rsp) ->
      bytype = {}
      for speaker in rsp.models
        unless bytype[speaker.get('type')]?
          bytype[speaker.get('type')] = []
        bytype[speaker.get('type')].push speaker.attributes
      dfr.resolve(bytype)
    return dfr.promise

module.exports = [Speaker, Speakers]