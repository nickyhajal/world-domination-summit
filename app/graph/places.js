const moment = require('moment');
const _ = require('lodash');
const _s = require('underscore.string');
const redis = require('redis');
const PlaceGraphType = require('./PlaceGraphType');

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

const Field = {
  type: PlaceGraphType,
  args: {
    place_id: { type: GraphQLString },
  },
  resolve: async (root, { place_id }) => {
    const place = await Place.forge({ place_id }).fetch();
    return place.attributes;
  },
};

const Fields = {
  type: new GraphQLList(PlaceGraphType),
  args: {
    orderBy: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const pls = Places.forge();
    if (args.orderBy !== undefined) {
      pls.query('orderByRaw', args.orderBy);
    } else {
      pls.query('orderBy', 'place_id', 'DESC');
    }
    const rows = await pls.fetch();
    return rows.models.map(row => row.attributes);
  },
};

const Add = {
  type: PlaceGraphType,
  args: {
    name: { type: new GraphQLNonNull(GraphQLString) },
    address: { type: new GraphQLNonNull(GraphQLString) },
    place_type: { type: new GraphQLNonNull(GraphQLString) },
    descr: { type: GraphQLString },
    pick: { type: GraphQLString },
  },
  resolve: async (obj, args) => {
    const { name } = args;
    const existing = await Place.forge({
      name,
    }).fetch();
    if (existing) {
      return Object.assign({}, { ...existing.attributes }, { existing: true });
    }
    const row = await Place.forge(args).save();
    setTimeout(() => {
      rds.expire('places', 0);
    }, 1000);
    return row.attributes;
  },
};

const Update = {
  type: PlaceGraphType,
  args: {
    place_id: { type: new GraphQLNonNull(GraphQLString) },
    name: { type: GraphQLString },
    address: { type: GraphQLString },
    place_type: { type: GraphQLString },
    descr: { type: GraphQLString },
    pick: { type: GraphQLString },
  },
  resolve: async (root, args, req) => {
    const { place_id } = args;
    const place = await Place.forge({ place_id }).fetch();
    await place.set(args).save();
    setTimeout(() => {
      rds.expire('places', 0);
    }, 1000);
    return place.attributes;
  },
};

const Delete = {
  type: PlaceGraphType,
  args: {
    place_id: { type: new GraphQLNonNull(GraphQLString) },
  },
  resolve: async (root, args, req) => {
    const { place_id } = args;
    const place = await Place.forge({ place_id }).fetch();
    if (place) {
      await place.destroy();
      setTimeout(() => {
        rds.expire('places', 0);
      }, 1000);
      return { existing: false };
    }
    return { existing: true };
  },
};
module.exports = {
  PlaceGraphType,
  Field,
  Add,
  Delete,
  Update,
  Fields,
};
