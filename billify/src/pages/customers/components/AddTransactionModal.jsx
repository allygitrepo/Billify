import React, { useState } from 'react';
import Modal from '../../../components/common/Modal';
import Input from '../../../components/common/Input';
import Select from '../../../components/common/Select';
import Button from '../../../components/common/Button';

const AddTransactionModal = ({ isOpen, onClose, onSubmit, type, customerName }) => {
  const isCredit = type === 'credit'; // Gave money / Red
  
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
