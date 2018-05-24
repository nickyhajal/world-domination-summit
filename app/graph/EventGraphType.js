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
const [User, Users] = require('../models/users');
const [Event, Events] = require('../models/events');
const [EventHost, EventHosts] = require('../models/event_hosts');
const UserGraph = require('./users');
const Type = new GraphQLObjectType({
  name: 'Event',
  description: 'Event',
  fields: () => ({
    event_id: {
      type: GraphQLInt,
      resolve: row => {
        return row.event_id;
      },
    },
    year: { type: GraphQLInt },
    active: { type: GraphQLString },
    ignored: { type: GraphQLString },
    type: { type: GraphQLString },
    for_type: { type: GraphQLString },
    format: { type: GraphQLString },
    outline: { type: GraphQLString },
    slug: { type: GraphQLString },
    descr: { type: GraphQLString },
    what: { type: GraphQLString },
    who: { type: GraphQLString },
    bios: {
      type: GraphQLString,
      resolve: ({ bios }) => {
        return bios
          ? bios.includes('{')
            ? bios
            : Buffer.from(bios, 'base64')
          : null;
      },
    },
    start: { type: GraphQLString },
    end: { type: GraphQLString },
    place: { type: GraphQLString },
    address: { type: GraphQLString },
    venue_note: { type: GraphQLString },
    lat: { type: GraphQLString },
    lon: { type: GraphQLString },
    note: { type: GraphQLString },
    startStr: {
      type: GraphQLString,
      resolve: row => moment(row.start).format('h:mm a'),
    },
    endStr: {
      type: GraphQLString,
      resolve: row => moment(row.end).format('h:mm a'),
    },
    dayStr: {
      type: GraphQLString,
      resolve: row => moment(row.start).format('dddd[,] MMMM Do'),
    },
    startDay: {
      type: GraphQLString,
      resolve: row => moment(row.start).format('YYYY-MM-DD'),
    },
    price: { type: GraphQLInt },
    pay_link: { type: GraphQLString },
    max: { type: GraphQLInt },
    num_rsvps: { type: GraphQLInt },
    free_max: { type: GraphQLInt },
    num_free: { type: GraphQLInt },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
    hosts: {
      type: new GraphQLList(UserGraph.Type),
      description: 'Event Host',
      resolve: async root => {
        const hosts = await Event.forge({ event_id: root.event_id }).hosts();
        return hosts.map(row => row.attributes);
      },
    },
  }),
});
module.exports = Type;