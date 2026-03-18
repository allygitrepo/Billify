import React, { useState, useMemo } from 'react';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import FormWrapper from '../../components/common/FormWrapper';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Table from '../../components/common/Table';

const Categories = () => {
  const { categories, addCategory, updateCategory } = useDataContext();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

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
  };

  const handleEdit = (category) => {
    setIsEditing(true);
    setEditingId(category.id);
    setFormData({
      name: category.name,
      description: category.description,
      status: category.status
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleCancel = () => {
    setIsEditing(false);
    setEditingId(null);
    setFormData({ name: '', description: '', status: 'active' });
    setErrors({});
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
    <PageContainer title="Category Management">
      <div className="animate-fade-in">
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

        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 'var(--spacing-6)', flexWrap: 'wrap', gap: 'var(--spacing-4)' }}>
            <h3 className="card-title">All Categories</h3>
            <div style={{ display: 'flex', gap: 'var(--spacing-4)', flex: '1', maxWidth: '500px', justifyContent: 'flex-end' }}>
              <Input
                placeholder="Search by name..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="search-input"
                style={{ marginBottom: 0 }}
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
                style={{ width: '150px', marginBottom: 0 }}
              />
            </div>
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
