const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLList,
} = require('graphql');
const [User, Users] = require('../models/users');
const [Event, Events] = require('../models/events');
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
    bios: { type: GraphQLString },
    start: { type: GraphQLString },
    end: { type: GraphQLString },
    place: { type: GraphQLString },
    address: { type: GraphQLString },
    venue_note: { type: GraphQLString },
    lat: { type: GraphQLString },
    lon: { type: GraphQLString },
    note: { type: GraphQLString },
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
        console.log('root', root);
        const hosts = await Event.forge({ event_id: root.event_id }).hosts();
        return hosts.map(row => row.attributes);
      },
    },
  }),
});
const Field = {
  type: Type,
  args: {
    event_id: { type: GraphQLString },
    slug: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const query = {};
    if (args.event_id !== undefined) query.event_id = args.event_id;
    if (args.slug !== undefined) query.slug = args.slug;
    const row = await Event.forge(query).fetch();
    return row.attributes;
  },
};
// const Create = {
//   type: Type,
//   args: {
//     value: {
//       description: 'The value name',
//       type: new GraphQLNonNull(GraphQLString),
//     },
//   },
//   resolve: async (obj, { value }) => {
//     const existing = await Value.forge({
//       value,
//     }).fetch();
//     if (existing) {
//       return Object.assign({}, { ...existing.attributes }, { existing: true });
//     }
//     const row = await Value.forge({
//       value,
//     }).save();
//     return row.attributes;
//   },
// };
const Fields = {
  type: new GraphQLList(Type),
  args: {
    type: { type: GraphQLString },
    year: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const evs = Events.forge();
    if (args.type !== undefined) {
      evs.query('where', 'type', args.type);
    }
    if (args.year !== undefined) {
      evs.query('where', 'year', args.year);
    }
    evs.query('orderBy', 'start');
    const rows = await evs.fetch();
    return rows.models.map(row => row.attributes);
  },
};

module.exports = {
  Type,
  Field,
  // Create,
  Fields,
};
