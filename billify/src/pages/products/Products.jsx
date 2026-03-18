import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import FormWrapper from '../../components/common/FormWrapper';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Table from '../../components/common/Table';
import Button from '../../components/common/Button';
import { formatCurrency } from '../../utils/formatCurrency';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';

const Products = () => {
  const { products, categories: allCategories, addProduct, updateProduct } = useDataContext();
  
  const categoryOptions = useMemo(() => {
    return allCategories.map(c => ({ label: c.name, value: c.name }));
  }, [allCategories]);

  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');

  // Form State
  const [showForm, setShowForm] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    category: '',
    description: '',
    basePrice: '',
    hsnCode: '',
    uom: 'Pcs',
    status: 'active',
    photo: '',
    variants: [{ id: Date.now(), name: '', sku: '', price: '', stock: '', status: 'active' }]
  });
  const [errors, setErrors] = useState({});

  // Handlers
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handleProductPhotoChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const error = validateImage(file);
    if (error) {
      setErrors(prev => ({ ...prev, photo: error }));
      return;
    }

    try {
      const base64 = await fileToBase64(file);
      setFormData(prev => ({ ...prev, photo: base64 }));
      setErrors(prev => ({ ...prev, photo: '' }));
    } catch (err) {
      setErrors(prev => ({ ...prev, photo: 'Error processing image.' }));
    }
  };

  const handleVariantChange = (index, e) => {
    const { name, value } = e.target;
    const newVariants = [...formData.variants];
    newVariants[index] = { ...newVariants[index], [name]: value };
    setFormData(prev => ({ ...prev, variants: newVariants }));
  };

  const addVariant = () => {
    setFormData(prev => ({
      ...prev,
      variants: [...prev.variants, { id: Date.now(), name: '', sku: '', price: '', stock: '', status: 'active' }]
    }));
  };

  const removeVariant = (index) => {
    if (formData.variants.length === 1) return;
    const newVariants = formData.variants.filter((_, i) => i !== index);
    setFormData(prev => ({ ...prev, variants: newVariants }));
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.name.trim()) newErrors.name = 'Product name is required';
    if (!formData.category) newErrors.category = 'Category is required';

    formData.variants.forEach((v, idx) => {
      if (!v.name.trim()) newErrors[`variant_name_${idx}`] = 'Required';
      if (!v.sku.trim()) newErrors[`variant_sku_${idx}`] = 'Required';
      if (v.price === '' || isNaN(v.price)) newErrors[`variant_price_${idx}`] = 'Invalid';
      if (v.stock === '' || isNaN(v.stock)) newErrors[`variant_stock_${idx}`] = 'Invalid';
    });

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleFormSubmit = () => {
    if (!validateForm()) return;

    // Simulate FormData
    const mockFormData = new FormData();
    Object.keys(formData).forEach(key => {
      mockFormData.append(key, formData[key]);
    });

    const processedData = {
      ...formData,
      basePrice: parseFloat(formData.basePrice) || 0,
      variants: formData.variants.map(v => ({
        ...v,
        price: parseFloat(v.price),
        stock: parseInt(v.stock)
      }))
    };

    if (isEditing) {
      updateProduct(editingId, processedData);
      setIsEditing(false);
      setEditingId(null);
    } else {
      addProduct(processedData);
    }

    resetForm();
    setShowForm(false);
  };

  const resetForm = () => {
    setFormData({
      name: '',
      category: '',
      description: '',
      basePrice: '',
      hsnCode: '',
      uom: 'Pcs',
      status: 'active',
      photo: '',
      variants: [{ id: Date.now(), name: '', sku: '', price: '', stock: '', status: 'active' }]
    });
    setErrors({});
    setShowForm(false);
    setIsEditing(false);
  };
  
  const handleCancel = () => {
    resetForm();
  };

  const handleEdit = (product) => {
    setIsEditing(true);
    setEditingId(product.id);
    setFormData({ ...product });
    setShowForm(true);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleStatusToggle = (id, currentStatus) => {
    updateProduct(id, { status: currentStatus === 'active' ? 'inactive' : 'active' });
  };

  // Bulk Upload Mocks
  const downloadTemplate = () => {
    alert('Downloading CSV Template...');
  };

  const handleFileUpload = () => {
    alert('File uploaded successfully! (Mock)');
  };

  // Filter Logic
  const filteredProducts = useMemo(() => {
    return products.filter(p => {
      const matchesSearch = p.name.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesCategory = categoryFilter === 'all' || p.category === categoryFilter;
      const matchesStatus = statusFilter === 'all' || p.status === statusFilter;
      return matchesSearch && matchesCategory && matchesStatus;
    });
  }, [products, searchTerm, categoryFilter, statusFilter]);

  // Table Columns
  const columns = [
    {
      key: 'photo',
      label: 'Image',
      render: (val) => (
        <div className="table-thumb">
          {val ? <img src={val} alt="Product" /> : null}
        </div>
      )
    },
    { key: 'name', label: 'Product Name' },
    { key: 'category', label: 'Category' },
    { 
      key: 'basePrice', 
      label: 'Base Price',
      render: (price) => formatCurrency(price)
    },
    { 
      key: 'variants', 
      label: 'Variants',
      render: (variants) => variants.length
    },
    {
      key: 'stock',
      label: 'Stock',
      render: (_, row) => {
        const lowest = Math.min(...row.variants.map(v => v.stock));
        return <span style={{ color: lowest <= 5 ? 'var(--danger-500)' : 'inherit', fontWeight: 'bold' }}>{lowest} (min)</span>;
      }
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
        <div style={{display: 'flex', gap: 'var(--spacing-3)'}}>
          <button className="btn-text" onClick={() => handleEdit(row)} style={{color: 'var(--primary-600)'}}>Edit</button>
          <button 
            className="btn-text" 
            onClick={() => handleStatusToggle(row.id, row.status)} 
            style={{color: row.status === 'active' ? 'var(--danger-500)' : 'var(--primary-600)'}}
          >
            {row.status === 'active' ? 'Disable' : 'Enable'}
          </button>
        </div>
      )
    }
  ];

  return (
    <PageContainer 
      title="Product Management"
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-4)', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          <div className="filters-row" style={{ maxWidth: '600px', margin: 0 }}>
            <Input placeholder="Search products..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
            <Select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)} options={[{label:'All Categories', value:'all'}, ...categoryOptions]} placeholder={null} />
            <Select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} options={[{label:'All Status', value:'all'}, {label:'Active', value:'active'}, {label:'Inactive', value:'inactive'}]} placeholder={null} />
          </div>
          <div style={{ display: 'flex', gap: 'var(--spacing-3)' }}>
            {!showForm ? (
              <Button variant="primary" onClick={() => setShowForm(true)}>+ Add Product</Button>
            ) : (
              <Button variant="secondary" onClick={handleCancel}>Back to List</Button>
            )}
            <Button variant="secondary" onClick={downloadTemplate}>Download Template</Button>
            <Button variant="secondary" onClick={handleFileUpload}>Upload CSV</Button>
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
          title={isEditing ? "Edit Product" : "Add New Product"}
          onSubmit={handleFormSubmit}
          onCancel={isEditing ? handleCancel : null}
          submitLabel={isEditing ? "Update Product" : "Save Product"}
        >
          <div className="product-layout-split">
            {/* Left Column: Add New Product fields */}
            <div className="product-left-col">
              <div className="product-form-grid">
                <div className="image-preview-rect" style={{ height: '100%', minHeight: '120px' }}>
                  {formData.photo ? <img src={formData.photo} alt="Preview" /> : <span style={{fontSize: '10px', color: 'var(--neutral-400)'}}>No Image</span>}
                </div>
                <div className="upload-field-container">
                  <Input 
                    label="Product Image" 
                    type="file" 
                    accept="image/*" 
                    onChange={handleProductPhotoChange} 
                    error={errors.photo} 
                    className="mb-0"
                  />
                  <p className="upload-hint">Square Image, Max 2MB</p>
                </div>
                <Input label="Product Name" name="name" value={formData.name} onChange={handleInputChange} error={errors.name} required />

                <Select label="Category" name="category" value={formData.category} onChange={handleInputChange} options={categoryOptions} error={errors.category} required />
                <Input label="HSN Code" name="hsnCode" value={formData.hsnCode} onChange={handleInputChange} />
                <Input label="UOM" name="uom" value={formData.uom} onChange={handleInputChange} />
                
                <Input label="Base Price" name="basePrice" type="number" value={formData.basePrice} onChange={handleInputChange} />
                <Select label="Status" name="status" value={formData.status} onChange={handleInputChange} options={[{label:'Active', value:'active'}, {label:'Inactive', value:'inactive'}]} />
                <div className="col-span-2">
                  <Input label="Description" name="description" value={formData.description} onChange={handleInputChange} />
                </div>
              </div>
            </div>

            {/* Right Column: Product Variants */}
            <div className="product-right-col">
              <div className="variants-section-split">
                <div className="section-header-compact">
                  <h3 className="section-title-small">Product Variants</h3>
                  <Button type="button" variant="secondary" onClick={addVariant} style={{ padding: '4px 12px', fontSize: '12px' }}>+ Add Variant</Button>
                </div>
                
                <div className="variants-list">
                  {formData.variants.map((v, idx) => (
                    <div key={v.id} className="variant-item-card-split">
                      <Input placeholder="Variant Name" name="name" value={v.name} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_name_${idx}`]} />
                      <Input placeholder="SKU" name="sku" value={v.sku} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_sku_${idx}`]} />
                      <Input placeholder="Price" name="price" type="number" value={v.price} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_price_${idx}`]} />
                      <Input placeholder="Stock" name="stock" type="number" value={v.stock} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_stock_${idx}`]} />
                      <Select 
                        name="status" 
                        value={v.status} 
                        onChange={(e) => handleVariantChange(idx, e)} 
                        options={[{label:'Active', value:'active'}, {label:'Inactive', value:'inactive'}]}
                        placeholder={null}
                      />
                      <Button type="button" variant="danger" onClick={() => removeVariant(idx)} disabled={formData.variants.length === 1}>×</Button>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </FormWrapper>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="card">
          <div style={{ marginBottom: 'var(--spacing-4)' }}>
            <h3 className="card-title">All Products</h3>
          </div>

          <Table columns={columns} data={filteredProducts} />
        </div>
      </div>
    </PageContainer>
  );
};

export default Products;
