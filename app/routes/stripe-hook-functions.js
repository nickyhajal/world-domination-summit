const stripe = require('stripe')(process.env.STRIPE_SK);
const [Transaction, Transactions] = require('../models/transactions');
const [User, Users] = require('../models/users');

const log = args => console.log('StripeHook: ', args);
const updateSub = async (id, sub, paidCount) => {
  const activeSub = await stripe.subscription.retrieve(id);
  activeSub.metadata.installments_paid = paidCount;
  await activeSub.save();
  if (paidCount > 3) {
    await activeSub.delete();
    log(`${sub.id} completed and deleted (paid ${paidCount} times)`);
  } else {
    log(`${sub.id} payment success (paid ${paidCount} times)`);
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
  await transaction.forge(row);
  return row;
};
const processInstallment = async (inv, sub, user, transaction) => {
  log(`start process installment`);
  const paidCount = sub.metadata.installments_paid + 1;
  await updateSub(sub.id);
  await updateUser(user, paidCount);
  await updateTransaction(inv, sub, user, transaction);
};
const processEvent = async event => {
  const inv = event.data.object;
  const sub = inv.lines.data[0];
  log(`process event: ${event.id}, ${inv.id}, ${sub.id}`);
  if (
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
    return true;
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
