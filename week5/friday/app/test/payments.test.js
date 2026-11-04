'use strict';

const assert = require('assert');
const { test } = require('./harness');
const {
  calculateTotal,
  formatCurrency,
  validateAmount,
  roundMoney
} = require('../src/payments');

test('calculateTotal sums a single item', () => {
  assert.strictEqual(calculateTotal([{ price: 10, quantity: 1 }]), 10);
});

test('calculateTotal applies quantity to each line', () => {
  assert.strictEqual(calculateTotal([
    { price: 10, quantity: 2 },
    { price: 5.5, quantity: 4 }
  ]), 42);
});

test('calculateTotal handles an empty basket', () => {
  assert.strictEqual(calculateTotal([]), 0);
});

test('calculateTotal rejects a negative price', () => {
  assert.throws(() => calculateTotal([{ price: -1, quantity: 1 }]), RangeError);
});

test('calculateTotal rejects a fractional quantity', () => {
  assert.throws(() => calculateTotal([{ price: 10, quantity: 1.5 }]), RangeError);
});

test('validateAmount rejects non numeric input', () => {
  assert.throws(() => validateAmount('10'), TypeError);
});

test('validateAmount rejects NaN', () => {
  assert.throws(() => validateAmount(Number.NaN), TypeError);
});

test('formatCurrency formats Kenyan shillings', () => {
  assert.strictEqual(formatCurrency(1234.5, 'KES'), 'KSh 1234.50');
});

test('formatCurrency rejects an unsupported currency', () => {
  assert.throws(() => formatCurrency(10, 'GBP'), RangeError);
});

test('roundMoney rounds to two decimal places', () => {
  assert.strictEqual(roundMoney(10.005), 10.01);
  assert.strictEqual(roundMoney(2.675), 2.68);
});
