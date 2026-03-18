import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import FormWrapper from '../../components/common/FormWrapper';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Table from '../../components/common/Table';import Button from '../../components/common/Button';

const Categories = () => {
  const { categories, addCategory, updateCategory } = useDataContext();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [showForm, setShowForm] = useState(false);

  // Form State
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    status: 'active'
  });
  const [errors, setErrors] = useState({});

  // Handlers
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.name.trim()) newErrors.name = 'Category name is required';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleFormSubmit = () => {
    if (!validateForm()) return;

    if (isEditing) {
      updateCategory(editingId, formData);
      setIsEditing(false);
      setEditingId(null);
    } else {
      addCategory(formData);
    }
    setFormData({ name: '', description: '', status: 'active' });
    setShowForm(false);
  };

  const handleEdit = (category) => {
    setIsEditing(true);
    setEditingId(category.id);
    setFormData({
      name: category.name,
      description: category.description,
      status: category.status
    });
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancel = () => {
    setIsEditing(false);
    setEditingId(null);
    setFormData({ name: '', description: '', status: 'active' });
    setErrors({});
    setShowForm(false);
  };

  const handleStatusToggle = (id, currentStatus) => {
    updateCategory(id, { status: currentStatus === 'active' ? 'inactive' : 'active' });
  };

  // Filtered Logic
  const filteredCategories = useMemo(() => {
    return categories.filter(cat => {
      const matchesSearch = cat.name.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesStatus = statusFilter === 'all' || cat.status === statusFilter;
      return matchesSearch && matchesStatus;
    });
  }, [categories, searchTerm, statusFilter]);

  // Table Columns
  const columns = [
    { key: 'name', label: 'Name' },
    { key: 'description', label: 'Description' },
    { key: 'productsCount', label: 'Total Products' },
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
        <div style={{ display: 'flex', gap: 'var(--spacing-3)' }}>
          <button
            className="btn-text"
            onClick={() => handleEdit(row)}
            style={{ color: 'var(--primary-600)' }}
          >
            Edit
          </button>
          <button
            className="btn-text"
            onClick={() => handleStatusToggle(row.id, row.status)}
            style={{ color: row.status === 'active' ? 'var(--danger-500)' : 'var(--primary-600)' }}
          >
            {row.status === 'active' ? 'Disable' : 'Enable'}
          </button>
        </div>
      )
    }
  ];

  return (
    <PageContainer 
      title="Category Management"
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-4)', alignItems: 'center', flexWrap: 'wrap' }}>
          <div className="filters-row" style={{ maxWidth: '400px', margin: 0 }}>
            <Input
              placeholder="Search by name..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="search-input"
            />
            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              options={[
                { label: 'All Status', value: 'all' },
                { label: 'Active', value: 'active' },
                { label: 'Inactive', value: 'inactive' }
              ]}
              placeholder={null}
            />
          </div>
          {!showForm ? (
            <Button variant="primary" onClick={() => setShowForm(true)}>+ Add Category</Button>
          ) : (
            <Button variant="secondary" onClick={handleCancel}>Back to List</Button>
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
              transition={{ duration: 0.3, ease: 'easeInOut' }}
              style={{ overflow: 'hidden' }}
            >
              <FormWrapper
          title={isEditing ? "Edit Category" : "Add New Category"}
          onSubmit={handleFormSubmit}
          onCancel={isEditing ? handleCancel : null}
          submitLabel={isEditing ? "Update Category" : "Add Category"}
        >
          <Input
            label="Category Name"
            name="name"
            placeholder="e.g. Beverages"
            value={formData.name}
            onChange={handleInputChange}
            error={errors.name}
            required
          />
          <Input
            label="Description"
            name="description"
            placeholder="Enter category description..."
            value={formData.description}
            onChange={handleInputChange}
          />
          <Select
            label="Status"
            name="status"
            value={formData.status}
            onChange={handleInputChange}
            options={[
              { label: 'Active', value: 'active' },
              { label: 'Inactive', value: 'inactive' }
            ]}
          />
        </FormWrapper>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="card">
          <div style={{ marginBottom: 'var(--spacing-4)' }}>
            <h3 className="card-title">All Categories</h3>
          </div>
          
          <Table
            columns={columns}
            data={filteredCategories}
          />
        </div>
      </div>
    </PageContainer>
  );
};

export default Categories;
