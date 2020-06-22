const moment = require('moment');
const _ = require('lodash');
const _s = require('underscore.string');
const redis = require('redis');
const RaceTaskGraphType = require('./RaceTaskGraphType');
const rds = redis.createClient();
const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');
const [RaceTask, RaceTasks] = require('../models/racetasks');

const Field = {
  type: RaceTaskGraphType,
  args: {
    racetask_id: { type: GraphQLString },
  },
  resolve: async (root, { racetask_id }) => {
    const racetask = await RaceTask.forge({ racetask_id }).fetch();
    return racetask.attributes;
  },
};

const Fields = {
  type: new GraphQLList(RaceTaskGraphType),
  args: {
    orderBy: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const tasks = RaceTasks.forge();
    if (args.orderBy !== undefined) {
      tasks.query('orderByRaw', args.orderBy);
    } else {
      tasks.query('orderBy', 'racetask_id', 'DESC');
    }
    const rows = await tasks.fetch();
    return rows.models.map(row => row.attributes);
  },
};

const Add = {
  type: RaceTaskGraphType,
  args: {
    task: { type: new GraphQLNonNull(GraphQLString) },
    section: { type: new GraphQLNonNull(GraphQLString) },
    type: { type: new GraphQLNonNull(GraphQLString) },
    points: { type: new GraphQLNonNull(GraphQLString) },
    descr: { type: GraphQLString },
    note: { type: GraphQLString },
    active: { type: GraphQLString },
    address: { type: GraphQLString },
    attendee_max: { type: GraphQLString },
    global_max: { type: GraphQLString },
  },
  resolve: async (obj, args) => {
    const { task } = args;
    const existing = await RaceTask.forge({
      task,
    }).fetch();
    if (existing) {
      return Object.assign({}, { ...existing.attributes }, { existing: true });
    }
    args.slug = _s.slugify(args.task);
    const row = await RaceTask.forge(args).save();
    setTimeout(() => {
      rds.expire('tasks', 0);
    }, 1000);
    return row.attributes;
  },
};

const Update = {
  type: RaceTaskGraphType,
  args: {
    racetask_id: { type: GraphQLString },
    task: { type: GraphQLString },
    section: { type: GraphQLString },
    type: { type: GraphQLString },
    slug: { type: GraphQLString },
    points: { type: GraphQLString },
    descr: { type: GraphQLString },
    note: { type: GraphQLString },
    active: { type: GraphQLString },
    address: { type: GraphQLString },
    attendee_max: { type: GraphQLString },
    global_max: { type: GraphQLString },
  },
  resolve: async (root, args, req) => {
    const { racetask_id } = args;
    const task = await RaceTask.forge({ racetask_id }).fetch();
    await task.set(args).save();
    setTimeout(() => {
      rds.expire('tasks', 0);
    }, 1000);
    return task.attributes;
  },
};

const Delete = {
  type: RaceTaskGraphType,
  args: {
    racetask_id: { type: new GraphQLNonNull(GraphQLString) },
  },
  resolve: async (root, args, req) => {
    const { racetask_id } = args;
    const task = await RaceTask.forge({ racetask_id }).fetch();
    if (task) {
      await task.destroy();
      setTimeout(() => {
        rds.expire('tasks', 0);
      }, 1000);
      return { existing: false };
    }
    return { existing: true };
  },
};
module.exports = {
  RaceTaskGraphType,
  Field,
  Add,
  Delete,
  Update,
  Fields,
};
