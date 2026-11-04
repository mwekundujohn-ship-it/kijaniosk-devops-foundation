'use strict';

const SUPPORTED_CURRENCIES = ['KES', 'USD', 'EUR'];

function roundMoney(value) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function validateAmount(amount) {
  if (typeof amount !== 'number' || Number.isNaN(amount)) {
    throw new TypeError('amount must be a number');
  }
  if (!Number.isFinite(amount)) {
    throw new RangeError('amount must be finite');
  }
  if (amount < 0) {
    throw new RangeError('amount must not be negative');
  }
  return true;
}

function calculateTotal(items) {
  if (!Array.isArray(items)) {
    throw new TypeError('items must be an array');
  }
  return items.reduce((sum, item) => {
    validateAmount(item.price);
    const quantity = item.quantity == null ? 1 : item.quantity;
    if (!Number.isInteger(quantity) || quantity < 1) {
      throw new RangeError('quantity must be a positive integer');
    }
    return sum + item.price * quantity;
  }, 0);
}

function formatCurrency(amount, currency) {
  validateAmount(amount);
  if (!SUPPORTED_CURRENCIES.includes(currency)) {
    throw new RangeError('unsupported currency: ' + currency);
  }
  const symbols = { KES: 'KSh', USD: '$', EUR: 'EUR' };
  return symbols[currency] + ' ' + roundMoney(amount).toFixed(2);
}

module.exports = {
  SUPPORTED_CURRENCIES,
  roundMoney,
  validateAmount,
  calculateTotal,
  formatCurrency
};
