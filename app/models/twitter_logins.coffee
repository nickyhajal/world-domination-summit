Shelf = require('./shelf')
Q = require('q')

TwitterLogin = Shelf.Model.extend
  tableName: 'twitter_logins'
  idAttribute: 'twitter_login_id'

TwitterLogins = Shelf.Collection.extend
  model: TwitterLogin

module.exports = [TwitterLogin, TwitterLogins]