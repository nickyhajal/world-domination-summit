const moment = require('moment');
const _s = require('underscore.string');

const {
  GraphQLString,
  GraphQLObjectType,
  GraphQLNonNull,
  GraphQLInt,
  GraphQLBoolean,
  GraphQLList,
} = require('graphql');
const [User, Users] = require('../models/users');
const [Page, Pages] = require('../models/pages');
const UserGraph = require('./users');
const Type = new GraphQLObjectType({
  name: 'Page',
  description: 'Page',
  fields: () => ({
    page_id: {
      type: GraphQLInt,
    },
    status: { type: GraphQLString },
    content: { type: GraphQLString },
    title: { type: GraphQLString },
    slug: { type: GraphQLString },
    author_id: { type: GraphQLString },
    created_at: { type: GraphQLString },
    updated_at: { type: GraphQLString },
    author: {
      type: UserGraph.Type,
      description: 'Customers',
      resolve: async root => {
        const user = await User.forge({ user_id: root.author_id }).fetch();
        return user ? user.attributes : {};
      },
    },
  }),
});
const Field = {
  type: Type,
  args: {
    page_id: { type: GraphQLString },
    slug: { type: GraphQLString },
  },
  resolve: async (root, { page_id, slug }, req) => {
    const query = {};
    if (slug !== undefined) {
      query.slug = slug;
    }
    if (page_id !== undefined) {
      query.page_id = page_id;
    }
    const page = await Page.forge(query).fetch();
    return page.attributes;
  },
};
const Fields = {
  type: new GraphQLList(Type),
  args: {
    status: { type: GraphQLString },
    sortBy: { type: GraphQLString },
    sortOrder: { type: GraphQLString },
  },
  resolve: async (root, args) => {
    const pages = Pages.forge();
    if (args.status !== undefined && args.status !== null) {
      pages.query('where', 'status', args.status);
    }
    pages.query(
      'orderBy',
      args.sortBy || 'created_at',
      args.sortOrder || 'desc'
    );
    const rows = await pages.fetch();
    return rows.models.map(row => (row ? row.attributes : null));
  },
};
const Update = {
  type: Type,
  args: {
    page_id: { type: GraphQLString },
    slug: { type: GraphQLString },
    content: { type: GraphQLString },
    title: { type: GraphQLString },
    status: { type: GraphQLString },
  },
  resolve: async (root, args, req) => {
    const query = {};
    const page = await Page.forge({
      page_id: args.page_id,
    }).fetch();
    if (args.content) {
      page.set('content', args.content);
    }
    if (args.title) {
      page.set('title', args.title);
    }
    if (args.status) {
      page.set('status', args.status);
    }
    const row = await page.save();
    return row.attributes;
  },
};
const Add = {
  type: Type,
  args: {
    content: { type: GraphQLString },
    title: { type: GraphQLString },
    status: { type: GraphQLString },
  },
  resolve: async (root, { content, title, status }, req) => {
    const query = {};
    const page = await Page.forge({
      content,
      title,
      status,
      slug: _s.slugify(title),
    });
    const row = await page.save();
    return row.attributes;
  },
};

module.exports = {
  Type,
  Field,
  Update,
  Add,
  Fields,
};
