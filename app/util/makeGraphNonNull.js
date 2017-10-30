const { GraphQLNonNull } = require('graphql');
const { assign, mapValues, pick } = require('lodash');

const makeNonNull = (obj, toMakeNonNull, toPick) => {
  const pickNonNull = toPick
    ? toPick === 'all' ? Object.keys(obj) : toPick
    : [];
  const pickThese = [...toMakeNonNull, ...pickNonNull];
  return mapValues(pick(obj, pickThese), (o, key) => {
    if (toMakeNonNull.includes(key)) {
      return assign({}, o, { type: new GraphQLNonNull(o.type) });
    }
    return o;
  });
};

module.exports = makeNonNull;
