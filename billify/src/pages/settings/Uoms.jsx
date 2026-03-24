import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import FormWrapper from '../../components/common/FormWrapper';
import Input from '../../components/common/Input';
import Table from '../../components/common/Table';
import Button from '../../components/common/Button';
import ConfirmDialog from '../../components/common/ConfirmDialog';

const Uoms = () => {
  const { uoms, addUom, updateUom, deleteUom } = useDataContext();
  const [searchTerm, setSearchTerm] = useState('');
  const [showForm, setShowForm] = useState(false);

  // Form State
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    shortCode: ''
  });
  const [errors, setErrors] = useState({});
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [uomToDelete, setUomToDelete] = useState(null);

  // Handlers
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.name.trim()) newErrors.name = 'Unit name is required';
    if (!formData.shortCode.trim()) newErrors.shortCode = 'Short code is required';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleFormSubmit = () => {
    if (!validateForm()) return;

    if (isEditing) {
      updateUom(editingId, formData);
    } else {
      addUom(formData);
    }
    handleCancel();
  };

  const handleEdit = (uom) => {
    setIsEditing(true);
    setEditingId(uom.id);
    setFormData({
      name: uom.name,
      shortCode: uom.shortCode
    });
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancel = () => {
    setIsEditing(false);
    setEditingId(null);
    setFormData({ name: '', shortCode: '' });
    setErrors({});
    setShowForm(false);
  };

  const handleDelete = (id) => {
    setUomToDelete(id);
    setIsConfirmOpen(true);
  };

  const filteredUoms = useMemo(() => {
    return (uoms || []).filter(u => 
      u.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.shortCode.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [uoms, searchTerm]);

  const columns = [
    { key: 'name', label: 'Unit Name' },
    { key: 'shortCode', label: 'Short Code' },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div style={{ display: 'flex', gap: 'var(--spacing-2)' }}>
          <button 
            className="btn-icon-primary" 
            onClick={() => handleEdit(row)}
            title="Edit Unit"
          >
            ✏️
          </button>
          <button 
            className="btn-icon-danger" 
            onClick={() => handleDelete(row.id)}
            title="Delete Unit"
          >
            🗑️
          </button>
        </div>
      )
    }
  ];

  return (
    <PageContainer 
      title="Units of Measurement" 
      description="Manage measurement units for your products"
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-6)' }}>
        {/* Actions Bar */}
        <div className="card" style={{ padding: 'var(--spacing-4)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 'var(--spacing-4)', flexWrap: 'wrap' }}>
            <div style={{ flex: 1, minWidth: '300px' }}>
              <Input
                placeholder="Search units..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                style={{ marginBottom: 0 }}
              />
            </div>
            <Button 
              variant="primary" 
              onClick={() => setShowForm(true)}
              disabled={showForm}
            >
              + Add New Unit
            </Button>
          </div>
        </div>

        {/* Form Container */}
        <AnimatePresence>
          {showForm && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
            >
              <FormWrapper
                title={isEditing ? 'Edit Unit' : 'Add New Unit'}
                onCancel={handleCancel}
                onSubmit={handleFormSubmit}
              >
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--spacing-4)' }}>
                  <Input
                    label="Unit Name"
                    name="name"
                    placeholder="e.g. Kilogram"
                    value={formData.name}
                    onChange={handleInputChange}
                    error={errors.name}
                    required
                  />
                  <Input
                    label="Short Code"
                    name="shortCode"
                    placeholder="e.g. Kg"
                    value={formData.shortCode}
                    onChange={handleInputChange}
                    error={errors.shortCode}
                    required
                  />
                </div>
              </FormWrapper>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Categories Table */}
        <div className="card">
          <div style={{ marginBottom: 'var(--spacing-4)' }}>
            <h3 className="card-title">All Units</h3>
          </div>
          <Table columns={columns} data={filteredUoms} />
        </div>
      </div>

      <ConfirmDialog
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={() => deleteUom(uomToDelete)}
        title="Delete Unit"
        message="Are you sure you want to delete this measurement unit? Products using this unit may need to be updated."
      />
    </PageContainer>
  );
};

export default Uoms;
