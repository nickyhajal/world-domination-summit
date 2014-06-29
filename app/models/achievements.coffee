Shelf = require('./shelf')
Bookshelf = require('bookshelf')
Q = require('q')

Achievement = Shelf.Model.extend
  tableName: 'achievement'
  hasTimestamps: true
  
Achievements = Shelf.Collection.extend
  model: Achievement

module.exports = [Achievement, Achievements]