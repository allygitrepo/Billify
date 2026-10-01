import React, { useState } from 'react';
import Modal from '../../../components/common/Modal';
import Input from '../../../components/common/Input';
import Select from '../../../components/common/Select';
import Button from '../../../components/common/Button';
import { formatCurrency } from '../../../utils/formatCurrency';

const AddTransactionModal = ({
  isOpen,
  onClose,
  onSubmit,
  type,
  customerName,
  currentBalance = 0
}) => {
  const isCredit = type === 'credit'; // Gave money / Red
  const balance = parseFloat(currentBalance || 0);

  const [formData, setFormData] = useState({
    amount: '',
    payment_method: 'Cash',
    note: '',
    date: new Date().toISOString().split('T')[0]
  });

  const [errors, setErrors] = useState({});

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const newErrors = {};
    if (!formData.amount || parseFloat(formData.amount) <= 0) {
      newErrors.amount = 'Please enter a valid amount';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    onSubmit(formData);
    setFormData({
      amount: '',
      payment_method: 'Cash',
      note: '',
      date: new Date().toISOString().split('T')[0]
    });
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isCredit ? `You Gave to ${customerName}` : `You Got from ${customerName}`}
    >
      <form onSubmit={handleSubmit}>
        <div style={{ padding: 'var(--spacing-6)' }}>
          {/* Current Pending Balance Status */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: 'var(--spacing-3) var(--spacing-4)',
            backgroundColor: balance > 0
              ? 'rgba(239, 68, 68, 0.08)'
              : balance < 0
                ? 'rgba(16, 185, 129, 0.08)'
                : 'var(--neutral-100)',
            border: `1px solid ${balance > 0 ? 'rgba(239, 68, 68, 0.25)' : balance < 0 ? 'rgba(16, 185, 129, 0.25)' : 'var(--neutral-200)'}`,
            borderRadius: 'var(--radius-lg)',
            marginBottom: 'var(--spacing-5)'
          }}>
            <div>
              <p style={{
                fontSize: '0.75rem',
                fontWeight: '700',
                color: balance > 0 ? 'var(--danger-700)' : balance < 0 ? 'var(--primary-700)' : 'var(--neutral-600)',
                textTransform: 'uppercase',
                letterSpacing: '0.05em'
              }}>
                {balance > 0
                  ? 'Pending Due'
                  : balance < 0
                    ? 'Advance Balance'
                    : 'Current Balance'}
              </p>
              <p style={{ fontSize: '0.75rem', color: 'var(--neutral-500)', marginTop: '2px' }}>
                {balance > 0
                  ? 'Customer owes you this amount'
                  : balance < 0
                    ? 'You owe customer this amount'
                    : 'All dues are settled'}
              </p>
            </div>
            <div style={{ textAlign: 'right', display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '4px' }}>
              <span style={{
                fontSize: '1.2rem',
                fontWeight: '800',
                color: balance > 0 ? 'var(--danger-600)' : balance < 0 ? 'var(--primary-600)' : 'var(--neutral-700)'
              }}>
                {formatCurrency(Math.abs(balance))}
              </span>
              {!isCredit && balance > 0 && (
                <button
                  type="button"
                  onClick={() => setFormData(prev => ({ ...prev, amount: balance.toFixed(2) }))}
                  style={{
                    background: 'none',
                    border: 'none',
                    color: 'var(--primary-600)',
                    fontSize: '0.75rem',
                    fontWeight: '700',
                    cursor: 'pointer',
                    textDecoration: 'underline',
                    padding: 0
                  }}
                >
                  Pay Full (₹{balance.toFixed(2)})
                </button>
              )}
            </div>
          </div>

          <Input
            label="Amount (₹)"
            name="amount"
            type="number"
            placeholder="0.00"
            value={formData.amount}
            onChange={handleInputChange}
            error={errors.amount}
            required
            autoFocus
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--spacing-4)', marginTop: '1rem' }}>
            <Input
              label="Date"
              name="date"
              type="date"
              value={formData.date}
              onChange={handleInputChange}
              required
            />
            <Select
              label="Payment Method"
              name="payment_method"
              value={formData.payment_method}
              onChange={handleInputChange}
              options={[
                { label: 'Cash', value: 'Cash' },
                { label: 'Online / UPI', value: 'Online' },
                { label: 'Bank Transfer', value: 'Bank' },
                { label: 'Cheque', value: 'Cheque' }
              ]}
              required
            />
          </div>

          <Input
            label="Notes / Remarks"
            name="note"
            placeholder="e.g. Paid against bill #101"
            value={formData.note}
            onChange={handleInputChange}
            style={{ marginTop: '1rem' }}
          />

          <div style={{ marginTop: '2rem', display: 'flex', gap: 'var(--spacing-3)' }}>
            <Button type="button" variant="secondary" onClick={onClose} block>Cancel</Button>
            <Button
              type="submit"
              variant={isCredit ? 'danger' : 'primary'}
              block
              style={{ backgroundColor: isCredit ? 'var(--danger-600)' : 'var(--primary-600)' }}
            >
              {isCredit ? 'Record Credit' : 'Record Payment'}
            </Button>
          </div>
        </div>
      </form>
    </Modal>
  );
};

export default AddTransactionModal;
