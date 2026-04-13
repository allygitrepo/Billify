import React, { useState, useMemo, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useNavigate, useLocation } from 'react-router-dom';
import { useDataContext } from '../../hooks/useDataContext';

import PageContainer from '../../components/layout/PageContainer';
import Table from '../../components/common/Table';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Button from '../../components/common/Button';
import FormWrapper from '../../components/common/FormWrapper';
import ToggleSwitch from '../../components/common/ToggleSwitch';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import { formatCurrency } from '../../utils/formatCurrency';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';


const Customers = () => {
  const { customers, addCustomer, updateCustomer, deleteCustomer, showToast } = useDataContext();
  const navigate = useNavigate();
  const location = useLocation();
  const fileInputRef = useRef(null);


  const [showForm, setShowForm] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  const [formData, setFormData] = useState({
    name: '',
    phone_number: '',
    opening_balance: 0,
    city: '',
    photo: '',
    status: 'active'
  });

  const [errors, setErrors] = useState({});
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [customerToDelete, setCustomerToDelete] = useState(null);

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    const val = type === 'checkbox' ? (checked ? 'active' : 'inactive') : value;
    setFormData(prev => ({ ...prev, [name]: val }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handlePhotoChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const validation = validateImage(file);
    if (!validation.isValid) {
      showToast(validation.error, 'error');
      return;
    }

    try {
      const base64 = await fileToBase64(file);
      // Remove prefix if backend expects raw base64
      const rawBase64 = base64.split(',')[1] || base64;
      setFormData(prev => ({ ...prev, photo: rawBase64 }));
    } catch (error) {
      showToast('Error processing image', 'error');
    }
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.name.trim()) newErrors.name = 'Name is required';
    if (!formData.phone_number.trim()) newErrors.phone_number = 'Phone number is required';
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!validateForm()) return;

    const payload = {
      ...formData,
      opening_balance: parseFloat(formData.opening_balance) || 0
    };

    if (isEditing) {
      await updateCustomer(editingId, payload);
    } else {
      await addCustomer(payload);
    }

    resetForm();
  };

  const handleEdit = (customer) => {
    setIsEditing(true);
    setEditingId(customer.id);
    setFormData({
      name: customer.name || '',
      phone_number: customer.phone_number || '',
      opening_balance: customer.opening_balance || 0,
      city: customer.city || '',
      photo: customer.photo || '',
      status: customer.status || 'active'
    });
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const resetForm = () => {
    setFormData({
      name: '',
      phone_number: '',
      opening_balance: 0,
      city: '',
      photo: '',
      status: 'active'
    });
    setErrors({});
    setShowForm(false);
    setIsEditing(false);
    setEditingId(null);
  };

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const editId = params.get('edit');
    if (editId && customers.length > 0) {
      const customer = customers.find(c => c.id === parseInt(editId));
      if (customer) {
        handleEdit(customer);
      }
    }
  }, [location.search, customers]);

  const handleRowClick = (customer) => {
    navigate(`/customers/${customer.id}`);
  };

  const handleEditClick = (e, customer) => {
    e.stopPropagation(); // Prevent row click
    handleEdit(customer);
  };

  const handleDeleteClick = (e, id) => {
    e.stopPropagation(); // Prevent row click
    setCustomerToDelete(id);
    setIsConfirmOpen(true);
  };


  const handleConfirmDelete = async () => {
    if (customerToDelete) {
      await deleteCustomer(customerToDelete);
      setIsConfirmOpen(false);
      setCustomerToDelete(null);
    }
  };

  const filteredCustomers = useMemo(() => {
    return (customers || []).filter(c => 
      c.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      c.phone_number?.includes(searchTerm) ||
      c.city?.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [customers, searchTerm]);

  const columns = [
    {
      key: 'photo',
      label: 'Photo',
      render: (val) => (
        <div className="table-thumb">
          <img 
            src={val ? `data:image/jpeg;base64,${val}` : "/placeholder.png"} 
            alt="Customer" 
            style={{ width: 40, height: 40, borderRadius: '50%', objectFit: 'cover' }} 
          />
        </div>
      )
    },
    { key: 'name', label: 'Customer Name' },
    { key: 'phone_number', label: 'Phone' },
    { key: 'city', label: 'City' },
    {
      key: 'remaining_balance',
      label: 'Balance',
      render: (val) => (
        <span style={{ 
          color: parseFloat(val || 0) > 0 ? 'var(--danger-500)' : 
                 parseFloat(val || 0) < 0 ? 'var(--primary-600)' : 'inherit',
          fontWeight: '600'
        }}>
          {formatCurrency(Math.abs(val || 0))}
          {parseFloat(val || 0) > 0 ? ' (Dr)' : parseFloat(val || 0) < 0 ? ' (Cr)' : ''}
        </span>
      )
    },
    {
      key: 'status',
      label: 'Status',
      render: (status) => (
        <span className={`status-badge ${status}`}>
          {status.charAt(0).toUpperCase() + status.slice(1)}
        </span>
      )
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div className="table-actions">
          <button className="btn-icon" onClick={(e) => handleEditClick(e, row)} title="Edit">✏️</button>
          <button className="btn-icon-danger" onClick={(e) => handleDeleteClick(e, row.id)} title="Delete">🗑</button>
        </div>
      )
    }

  ];

  return (
    <PageContainer 
      title="Customer Management" 
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-4)' }}>
          <Input 
            placeholder="Search customers..." 
            value={searchTerm} 
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{ width: '300px' }}
          />
          {!showForm && (
            <Button variant="primary" onClick={() => setShowForm(true)}>+ Add Customer</Button>
          )}
        </div>
      }
    >
      <div className="animate-fade-in">
        <AnimatePresence>
          {showForm && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="mb-8 overflow-hidden"
            >
              <FormWrapper
                title={isEditing ? "Edit Customer" : "Add New Customer"}
                onSubmit={handleFormSubmit}
                onCancel={resetForm}
                submitLabel={isEditing ? "Update Customer" : "Save Customer"}
              >
                <div className="product-form-grid">
                  <div className="form-col">
                    <div className="image-upload-wrapper mb-6">
                      <div className="image-preview-circle">
                        {formData.photo ? (
                          <img src={`data:image/jpeg;base64,${formData.photo}`} alt="Preview" />
                        ) : (
                          <span>👤</span>
                        )}
                      </div>
                      <div className="upload-field-container">
                        <Button type="button" variant="secondary" onClick={() => fileInputRef.current.click()}>
                          {formData.photo ? 'Change Photo' : 'Upload Photo'}
                        </Button>
                        <p className="upload-hint">Square Image, Max 1MB</p>
                        <input 
                          type="file" 
                          ref={fileInputRef} 
                          onChange={handlePhotoChange} 
                          accept="image/*" 
                          style={{ display: 'none' }} 
                        />
                      </div>
                    </div>

                    <Input 
                      label="Customer Name" 
                      name="name" 
                      value={formData.name} 
                      onChange={handleInputChange} 
                      error={errors.name} 
                      required 
                    />
                    <Input 
                      label="Phone Number" 
                      name="phone_number" 
                      value={formData.phone_number} 
                      onChange={handleInputChange} 
                      error={errors.phone_number} 
                      required 
                    />
                  </div>
                  
                  <div className="form-col">
                    <Input 
                      label="City" 
                      name="city" 
                      value={formData.city} 
                      onChange={handleInputChange} 
                    />
                    <Input 
                      label="Opening Balance" 
                      name="opening_balance" 
                      type="number"
                      value={formData.opening_balance} 
                      onChange={handleInputChange}
                      placeholder="Amount customer owes you"
                      disabled={isEditing} // Lock opening balance on edit
                    />
                    <ToggleSwitch 
                      label="Active Status" 
                      name="status" 
                      checked={formData.status === 'active'} 
                      onChange={handleInputChange} 
                    />
                  </div>
                </div>
              </FormWrapper>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="card">
          <Table 
            columns={columns} 
            data={filteredCustomers} 
            onRowClick={handleRowClick}
          />
        </div>

      </div>

      <ConfirmDialog
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={handleConfirmDelete}
        title="Delete Customer"
        message="Are you sure you want to delete this customer? This will hide them from the list."
      />
    </PageContainer>
  );
};

export default Customers;
