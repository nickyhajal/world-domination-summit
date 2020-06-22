const Shelf = require('./shelf');

const RaceUserPrize = Shelf.Model.extend({
  tableName: 'race_user_prizes',
  idAttribute: 'race_user_prize_id',
});

const RaceUserPrizes = Shelf.Collection.extend({
  model: RaceUserPrize,
});

module.exports = [RaceUserPrize, RaceUserPrizes];
