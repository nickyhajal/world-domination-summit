Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')

Registration = Shelf.Model.extend
  tableName: 'registrations'
  hasTimestamps: true
  
Registrations = Shelf.Collection.extend
  model: Registration

module.exports = [Registration, Registrations]