Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')

Ticket = Shelf.Model.extend
  tableName: 'tickets'
  idAttribute: 'ticket_id'
  hasTimestamps: true

Tickets = Shelf.Collection.extend
  model: Ticket

module.exports = [Ticket, Tickets]