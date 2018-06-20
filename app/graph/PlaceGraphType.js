const moment = require('moment');
const _ = require('lodash');
const _s = require('underscore.string');
const redis = require('redis');
const rds = redis.createClient();

const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');
const [Place, Places] = require('../models/places');
const [PlaceType, PlaceTypes] = require('../models/placetypes');
const Type = new GraphQLObjectType({
  name: 'Place',
  description: 'Place',
  fields: () => ({
    place_: { type: GraphQLString },
    name: { type: GraphQLString },
    place_type: { type: GraphQLString },
    type: {
      type: GraphQLString,
      resolve: async ({ place_type }) => {
        const ptype = await PlaceType.forge({
          placetypeid: place_type,
        }).fetch();
        return ptype.get('type_name');
      },
    },
    pick: { type: GraphQLString },
    lat: { type: GraphQLString },
    lon: { type: GraphQLString },
    address: { type: GraphQLString },
    existing: { type: GraphQLBoolean },
    descr: { type: GraphQLString },
    stamp: { type: GraphQLString },
  }),
});
module.exports = Type;
