Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')

SpeakerQuote = Shelf.Model.extend
  tableName: 'speaker_quotes'
  permittedAttributes: [
    'quote_id', 'speaker_id', 'quote'
  ]
SpeakerQuotes = Shelf.Collection.extend
  model: SpeakerQuote

module.exports = [SpeakerQuote, SpeakerQuotes]