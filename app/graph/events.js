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
    bios: { type: GraphQLString },
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
    price: { type: GraphQLInt },
    pay_link: { type: GraphQLString },
    max: { type: GraphQLInt },
    num_rsvps: { type: GraphQLInt },
    free_max: { type: GraphQLInt },
    num_free: { type: GraphQLInt },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
    showInactive: { type: GraphQLBoolean },
  },
  resolve: async (root, args) => {
    const evs = Events.forge();
    if (args.type !== undefined && args.type !== null) {
      evs.query('where', 'type', args.type);
    }
    if (args.year !== undefined && args.year !== null) {
      evs.query('where', 'year', args.year);
    }
    if (args.showInactive === undefined) {
      evs.query('where', 'active', '1');
    }
    evs.query('orderBy', 'start');
    const rows = await evs.fetch();
    return rows.models.map(row => row.attributes);
  },
};

const Args = {
  year: { type: GraphQLString },
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
  hosts: { type: GraphQLString },
  hour: { type: GraphQLString },
  minute: { type: GraphQLString },
  ampm: { type: GraphQLString },
  date: { type: GraphQLString },
  end_hour: { type: GraphQLString },
  end_minute: { type: GraphQLString },
  end_ampm: { type: GraphQLString },
  place: { type: GraphQLString },
  address: { type: GraphQLString },
  venue_note: { type: GraphQLString },
  lat: { type: GraphQLString },
  lon: { type: GraphQLString },
  note: { type: GraphQLString },
  price: { type: GraphQLInt },
  pay_link: { type: GraphQLString },
  max: { type: GraphQLInt },
  free_max: { type: GraphQLInt },
};

const Add = {
  type: Type,
  args: Args,
  resolve: async (root, args) => {
    const post = _.pick(args, Event.prototype.permittedAttributes);
    let {
      what,
      date,
      hour,
      minute,
      ampm,
      end_hour,
      end_minute,
      type,
      end_ampm,
      hosts,
    } = args;
    const month = `-0${+date > 20 ? '6' : '7'}-`;
    const start = moment.utc(
      process.year + month + date + ' ' + hour + ':' + minute + ':00',
      'YYYY-MM-DD HH:mm:ss'
    );
    if (hour === '12') {
      ampm = Math.abs(ampm - 12);
    }
    post.start = start.add('hours', ampm).format('YYYY-MM-DD HH:mm:ss');

    // Parse End Time if we have one
    if (end_hour != null && end_minute != null) {
      const end = moment.utc(
        process.year + month + date + ' ' + end_hour + ':' + end_minute + ':00',
        'YYYY-MM-DD HH:mm:ss'
      );
      if (end_hour === '12') {
        end_ampm = Math.abs(end_ampm - 12);
      }
      post.end = end.add('hours', end_ampm).format('YYYY-MM-DD HH:mm:ss');
    }

    if (type == null) {
      type = 'meetup';
    }

    post.slug = _s.slugify(what);
    const slugs = await Events.query(qb =>
      qb.where('slug', 'LIKE', `${post.slug}%`)
    ).fetch();
    if (slugs.models.length) {
      if (slugs.models.length) {
        post.slug += `-${slugs.models.length + 1}`;
      }
    }
    post.year = process.yr;
    const event = await Event.forge(post).save();
    setTimeout(() => rds.expire('events', 0), 1000);
    if (hosts != null) {
      const ids = hosts.split(',').map(id =>
        EventHost.forge({
          event_id: event.get('event_id'),
          user_id: id,
        }).save()
      );
      await Promise.all(ids);
    }
    return event.attributes;
  },
};

module.exports = {
  Type,
  Field,
  Add,
  Fields,
};
