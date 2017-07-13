Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')

Registration = Shelf.Model.extend
  tableName: 'registrations'
  idAttribute: 'registration_id'
  hasTimestamps: true
  
Registrations = Shelf.Collection.extend
  model: Registration

module.exports = [Registration, Registrations]