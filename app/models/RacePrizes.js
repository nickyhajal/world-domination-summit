const Shelf = require('./shelf');

const RacePrize = Shelf.Model.extend({
  tableName: 'race_prizes',
  idAttribute: 'prize_id',
});

const RacePrizes = Shelf.Collection.extend({
  model: RacePrize,
});

module.exports = [RacePrize, RacePrizes];
