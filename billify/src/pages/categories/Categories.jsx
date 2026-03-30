import React, { useState, useMemo, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import FormWrapper from '../../components/common/FormWrapper';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Table from '../../components/common/Table';
import Button from '../../components/common/Button';
import ToggleSwitch from '../../components/common/ToggleSwitch';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import { exportToCSV, importFromCSV, downloadTemplate as downloadCSVTemplate } from '../../utils/csvService';

const Categories = () => {
  const fileInputRef = useRef(null);
  const { categories, products, addCategory, updateCategory, deleteCategory, showToast } = useDataContext();
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
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [categoryToDelete, setCategoryToDelete] = useState(null);

  // Handlers
  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    const val = type === 'checkbox' ? (checked ? 'active' : 'inactive') : value;
    setFormData(prev => ({ ...prev, [name]: val }));
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

  const handleDelete = (id) => {
    setCategoryToDelete(id);
    setIsConfirmOpen(true);
  };

  // Bulk Handlers
  const handleDownloadTemplate = () => {
    downloadCSVTemplate(['name', 'description'], 'categories_template');
  };

  const handleExportCategories = () => {
    const exportData = categories.map(cat => ({
      name: cat.name,
      description: cat.description,
      status: cat.status,
      productsCount: cat.productsCount
    }));
    exportToCSV(exportData, 'billify_categories');
  };

  const handleImportCSV = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    try {
      const data = await importFromCSV(file);
      data.forEach(item => {
        if (item.name) {
          addCategory({
            name: item.name,
            description: item.description || '',
            status: 'active'
          });
        }
      });
      showToast(`Imported ${data.length} categories!`, 'success');
      e.target.value = '';
    } catch (err) {
      showToast('Error importing categories: ' + err.message, 'error');
    }
  };

  // Filtered Logic
  const filteredCategories = useMemo(() => {
    return categories
      .map(cat => ({
        ...cat,
        productsCount: products.filter(p => p.category === cat.name).length
      }))
      .filter(cat => {
        const matchesSearch = cat.name.toLowerCase().includes(searchTerm.toLowerCase());
        const matchesStatus = statusFilter === 'all' || cat.status === statusFilter;
        return matchesSearch && matchesStatus;
      });
  }, [categories, products, searchTerm, statusFilter]);

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
        <div style={{display: 'flex', gap: 'var(--spacing-2)'}}>
          <button
            className="btn-icon-primary"
            onClick={() => handleEdit(row)}
            title="Edit Category"
          >
            ✏️
          </button>
          <button
            className="btn-icon-danger"
            onClick={() => handleDelete(row.id)}
            title="Delete Category"
          >
            🗑️
          </button>
        </div>
      )
    }
  ];

  return (
    <PageContainer 
      title="Category Management"
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-4)', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
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
          <div style={{ display: 'flex', gap: 'var(--spacing-3)' }}>
            {!showForm ? (
              <Button variant="primary" onClick={() => setShowForm(true)}>+ Add Category</Button>
            ) : (
              <Button variant="secondary" onClick={handleCancel}>Back to List</Button>
            )}
            <Button variant="secondary" onClick={handleDownloadTemplate}>Template</Button>
            <Button variant="secondary" onClick={() => fileInputRef.current.click()}>Import</Button>
            <Button variant="secondary" onClick={handleExportCategories}>Export</Button>
            <input 
              type="file" 
              ref={fileInputRef} 
              style={{ display: 'none' }} 
              accept=".csv" 
              onChange={handleImportCSV} 
            />
          </div>
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
          <ToggleSwitch 
            label="Category Status" 
            name="status" 
            checked={formData.status === 'active'} 
            onChange={handleInputChange} 
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
      <ConfirmDialog 
        isOpen={isConfirmOpen} 
        onClose={() => setIsConfirmOpen(false)} 
        onConfirm={() => deleteCategory(categoryToDelete)} 
        title="Delete Category"
        message="Are you sure you want to permanently delete this category? This will also delete all associated products and cannot be undone."
      />
    </PageContainer>
  );
};

export default Categories;
