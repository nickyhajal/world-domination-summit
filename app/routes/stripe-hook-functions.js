const stripe = require('stripe')(process.env.STRIPE_SK);
const [Transaction, Transactions] = require('../models/transactions');
const [User, Users] = require('../models/users');
const [StripeEvent, StripeEvents] = require('../models/StripeEvents');

const log = args => console.log('StripeHook: ', args);
const updateSub = async (id, paidCount) => {
  await stripe.subscriptions.update(id, {
    metadata: { installments_paid: paidCount },
  });
  if (paidCount > 3) {
    await stripe.subscriptions.del(id);
    log(`${id} completed and deleted (paid ${paidCount} times)`);
  } else {
    log(`${id} payment success (paid ${paidCount} times)`);
  }
  return true;
};
const updateUser = async (user, paidCount) => {
  const upd = { plan_installments: paidCount };
  log(`update user: ${upd}`);
  await user.set(upd).save();
  return upd;
};
const updateTransaction = async (inv, sub, user, transaction) => {
  const row = {
    user_id: user.get('user_id'),
    status: 'paid',
    product_id: '2011',
    via: 'hook',
    stripe_id: inv.charge,
    paid_amount: inv.amount_paid,
    quantity: sub.quantity,
    subscription_type: 'installment',
    subscription_id: inv.id,
    meta: transaction.get('transaction_id'),
  };
  log(`create transaction: ${row}`);
  await Transaction.forge(row).save();
  return row;
};
const processInstallment = async (inv, sub, user, transaction) => {
  log(`start process installment`);
  console.log(sub.metadata);
  const paidCount = +sub.metadata.installments_paid + 1;
  await updateSub(sub.id, paidCount);
  await updateUser(user, paidCount);
  await updateTransaction(inv, sub, user, transaction);
};
const checkIfEventExists = async event => {
  const row = StripeEvent.forge({ service_id: event.id });
  const existing = await row.fetch();
  return existing;
};
const recordEvent = async event => {
  const row = StripeEvent.forge({
    service_id: event.id,
    status: 'processing',
    type: event.type,
  });
  await row.save();
  return row;
};
const processEvent = async event => {
  const exists = await checkIfEventExists(event);
  if (!exists) {
    const record = await recordEvent(event);
    if (event && event.type === 'invoice.payment_succeeded') {
      const inv = event.data.object;
      const sub = inv.lines.data[0];
      log(`process event: ${event.id}, ${inv.id}, ${sub.id}`);
      if (
        inv.charge &&
        sub.metadata &&
        sub.metadata.installments_paid &&
        +sub.metadata.installments_paid > 0
      ) {
        log(`get assets for process installment paid`);
        const transaction = await Transaction.forge({
          subscription_id: sub.id,
        }).fetch();
        const user = await User.forge({
          user_id: transaction.get('user_id'),
        }).fetch();
        await processInstallment(inv, sub, user, transaction);
        record.set({ status: 'success' }).save();
        return true;
      } else {
        record
          .set({
            status: inv.charge ? 'ignored-trial-invoice' : 'ignored-no-meta',
          })
          .save();
      }
    } else {
      record.set({ status: 'ignored-not-invoice' }).save();
      console.log('Stripe Hook: ', event.type);
    }
  } else {
    console.log('Ignored duplicate event: ', event.id);
  }
  return false;
};

module.exports = {
  updateSub,
  updateUser,
  updateTransaction,
  processInstallment,
  processEvent,
};
