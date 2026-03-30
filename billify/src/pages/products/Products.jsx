import React, { useState, useMemo, useRef, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
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
import { formatCurrency } from '../../utils/formatCurrency';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';
import { exportToCSV, importFromCSV, downloadTemplate as downloadCSVTemplate } from '../../utils/csvService';

const Products = () => {
  const fileInputRef = useRef(null);
  const { products, categories: allCategories, uoms, addProduct, updateProduct, deleteProduct, showToast, settings } = useDataContext();

  const categoryOptions = useMemo(() => {
    return [
      { label: 'No Category', value: '' },
      ...allCategories.map(c => ({ label: c.name, value: c.name }))
    ];
  }, [allCategories]);

  const [searchParams] = useSearchParams();
  const initialFilter = searchParams.get('filter') || 'all';

  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState(initialFilter);

  // Update filter if URL changes
  useEffect(() => {
    const filter = searchParams.get('filter');
    if (filter) setStatusFilter(filter);
  }, [searchParams]);

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
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);

  // Handlers
  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    const val = type === 'checkbox' ? (checked ? 'active' : 'inactive') : value;
    setFormData(prev => ({ ...prev, [name]: val }));
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
    const { name, value, type, checked } = e.target;
    const val = type === 'checkbox' ? (checked ? 'active' : 'inactive') : value;
    const newVariants = [...formData.variants];
    newVariants[index] = { ...newVariants[index], [name]: val };
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
    if (settings.categoryCompulsory && !formData.category) newErrors.category = 'Category is required';

    formData.variants.forEach((v, idx) => {
      if (settings.variantsEnabled && !v.name.trim()) newErrors[`variant_name_${idx}`] = 'Required';
      // SKU is optional
      if (v.price === '' || isNaN(v.price)) newErrors[`variant_price_${idx}`] = 'Invalid';
      if (v.stock === '' || isNaN(v.stock)) newErrors[`variant_stock_${idx}`] = 'Invalid';
    });

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleFormSubmit = () => {
    // If variants are disabled, ensure the single variant has a default name
    if (!settings.variantsEnabled) {
      const newVariants = [...formData.variants];
      newVariants[0] = { ...newVariants[0], name: 'Standard' };
      setFormData(prev => ({ ...prev, variants: newVariants }));
      // We'll use the updated data for validation
    }

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

  const handleDelete = (id) => {
    setProductToDelete(id);
    setIsConfirmOpen(true);
  };

  // Bulk Upload/Export Handlers
  const handleDownloadTemplate = () => {
    downloadCSVTemplate(
      ['name', 'category', 'description', 'basePrice', 'hsnCode', 'uom', 'variantName', 'sku', 'price', 'stock'],
      'products_template'
    );
  };

  const handleExportProducts = () => {
    const exportData = products.flatMap(p =>
      p.variants.map(v => ({
        id: p.id,
        name: p.name,
        category: p.category,
        hsnCode: p.hsnCode || '',
        uom: p.uom || 'Pcs',
        variantName: v.name,
        sku: v.sku,
        price: v.price,
        stock: v.stock,
        status: p.status
      }))
    );
    exportToCSV(exportData, 'billify_products');
  };

  const handleImportCSV = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    try {
      const data = await importFromCSV(file);

      // Normalize: create a lowercase-keyed version of each row to handle any header casing
      const normalizedData = data.map(item => {
        const normalized = {};
        Object.keys(item).forEach(key => {
          // Convert "Product Name" -> "productname", "basePrice" -> "baseprice" etc.
          normalized[key.toLowerCase().replace(/\s+/g, '')] = item[key];
        });
        // Also keep original keys so we don't break anything
        return { ...normalized };
      });

      // Helper: get a field trying multiple possible key names
      const getField = (row, ...keys) => {
        for (const key of keys) {
          const normalized = key.toLowerCase().replace(/\s+/g, '');
          if (row[normalized] !== undefined && row[normalized] !== '') {
            return row[normalized];
          }
        }
        return undefined;
      };

      // Group variants by product name
      const productsMap = {};
      normalizedData.forEach(item => {
        const name = getField(item, 'name', 'productname', 'productName', 'product');
        if (!name || !name.trim()) return;

        const key = name.trim();
        if (!productsMap[key]) {
          productsMap[key] = {
            name: key,
            category: getField(item, 'category', 'categoryname') || 'General',
            description: getField(item, 'description', 'desc') || '',
            basePrice: parseFloat(getField(item, 'baseprice', 'basePrice', 'price') || '0') || 0,
            hsnCode: getField(item, 'hsncode', 'hsnCode', 'hsn') || '',
            uom: getField(item, 'uom', 'unit') || 'Pcs',
            status: 'active',
            variants: []
          };
        }
        productsMap[key].variants.push({
          id: Date.now() + Math.random(),
          name: getField(item, 'variantname', 'variantName', 'variant') || 'Default',
          sku: getField(item, 'sku') || `SKU-${Math.floor(Math.random() * 10000)}`,
          price: parseFloat(getField(item, 'price', 'sellingprice', 'sellingPrice') || '0') || 0,
          stock: parseInt(getField(item, 'stock', 'quantity', 'qty') || '0') || 0,
          status: 'active'
        });
      });

      const count = Object.values(productsMap).length;
      if (count === 0) {
        showToast('No valid products found in CSV. Check column headers.', 'error');
        e.target.value = '';
        return;
      }

      // Add each product to the context sequentially to handle potential conflicts
      const products = Object.values(productsMap);
      let successCount = 0;
      let updateCount = 0;
      let skipCount = 0;

      for (const product of products) {
        try {
          await addProduct(product);
          successCount++;
        } catch (error) {
          if (error.status === 409 && error.existingProduct) {
            const shouldUpdate = window.confirm(
              `Product with HSN ${product.hsnCode} ("${error.existingProduct.name}") already exists. \n\nDo you want to UPDATE it with the new data from CSV?`
            );
            if (shouldUpdate) {
              await updateProduct(error.existingProduct.id, product);
              updateCount++;
            } else {
              skipCount++;
            }
          } else {
            console.error('Import error for product:', product.name, error);
            skipCount++;
          }
        }
      }

      alert(`Import complete!\n- New products: ${successCount}\n- Updated: ${updateCount}\n- Skipped: ${skipCount}`);
      e.target.value = '';
    } catch (err) {
      showToast('Error importing CSV: ' + err.message, 'error');
    }
  };

  // Filter Logic
  const filteredProducts = useMemo(() => {
    return products.filter(p => {
      const name = p.name || '';
      const category = p.category || '';
      const status = p.status || '';

      const matchesSearch = name.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesCategory = categoryFilter === 'all' || category === categoryFilter;

      let matchesStatus = statusFilter === 'all' || status === statusFilter;
      if (statusFilter === 'low_stock') {
        const hasLowStock = p.variants?.some(v => (parseInt(v.stock) || 0) <= 10);
        matchesStatus = hasLowStock;
      }

      return matchesSearch && matchesCategory && matchesStatus;
    });
  }, [products, searchTerm, categoryFilter, statusFilter]);

  // Derived Table Data (Flattened for Low Stock View)
  const tableData = useMemo(() => {
    if (statusFilter !== 'low_stock') return filteredProducts;

    // For low stock, flatten variants into individual rows
    return filteredProducts.flatMap(p => 
      (p.variants || [])
        .filter(v => (parseInt(v.stock) || 0) <= 10)
        .map(v => ({
          ...p,
          variantName: v.name,
          variantPrice: v.price,
          variantStock: v.stock,
          isLowStockView: true
        }))
    );
  }, [filteredProducts, statusFilter]);

  // Table Columns (Dynamic)
  const columns = useMemo(() => {
    const defaultColumns = [
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
        render: (variants) => (
          <div className="variants-cell">
            <span className="variants-count">{(variants || []).length} Variants</span>
            <div className="variants-tooltip">
              <p style={{ margin: '0 0 8px 0', fontSize: '10px', textTransform: 'uppercase', color: 'var(--neutral-400)', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '4px' }}>Variant Details</p>
              {(variants || []).map((v, i) => (
                <div key={i} className="tooltip-item">
                  <span className="v-name">{v.name || 'Standard'}</span>
                  <span className={`v-stock ${(parseInt(v.stock) || 0) <= 10 ? 'low' : ''}`}>{v.stock} unit</span>
                </div>
              ))}
            </div>
          </div>
        )
      },
      {
        key: 'stock',
        label: 'Stock',
        render: (_, row) => {
          const variants = row.variants || [];
          if (variants.length === 0) return '0';
          const lowest = Math.min(...variants.map(v => parseInt(v.stock) || 0));
          return <span style={{ color: lowest <= 10 ? 'var(--danger-500)' : 'inherit', fontWeight: 'bold' }}>{lowest}</span>;
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
      }
    ];

    const lowStockColumns = [
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
      { key: 'variantName', label: 'Variant Name' },
      {
        key: 'variantPrice',
        label: 'Price',
        render: (val) => formatCurrency(val)
      },
      {
        key: 'variantStock',
        label: 'Stock Status',
        render: (val) => (
          <span style={{ color: 'var(--danger-500)', fontWeight: 'bold' }}>
            {val} (Low)
          </span>
        )
      }
    ];

    const activeColumns = statusFilter === 'low_stock' ? lowStockColumns : defaultColumns;

    return [
      ...activeColumns,
      {
        key: 'actions',
        label: 'Actions',
        render: (_, row) => (
          <div style={{ display: 'flex', gap: 'var(--spacing-2)' }}>
            <button
              className="btn-icon-primary"
              onClick={() => handleEdit(row)}
              title="Edit Product"
            >
              ✏️
            </button>
            {!row.isLowStockView && (
              <button
                className="btn-icon-danger"
                onClick={() => handleDelete(row.id)}
                title="Delete Product"
              >
                🗑️
              </button>
            )}
          </div>
        )
      }
    ];
  }, [statusFilter, products]); // products as dependency for tooltips/stock

  return (
    <PageContainer
      title="Product Management"
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-4)', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          <div className="filters-row" style={{ maxWidth: '600px', margin: 0 }}>
            <Input placeholder="Search products..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
            <Select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value)} options={[{ label: 'All Categories', value: 'all' }, ...categoryOptions]} placeholder={null} />
            <Select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} options={[
              { label: 'All Status', value: 'all' },
              { label: 'Active', value: 'active' },
              { label: 'Inactive', value: 'inactive' },
              { label: 'Low Stock', value: 'low_stock' }
            ]} placeholder={null} />
          </div>
          <div style={{ display: 'flex', gap: 'var(--spacing-3)' }}>
            {!showForm ? (
              <Button variant="primary" onClick={() => setShowForm(true)}>+ Add Product</Button>
            ) : (
              <Button variant="secondary" onClick={handleCancel}>Back to List</Button>
            )}
            <Button variant="secondary" onClick={handleDownloadTemplate}>Download Template</Button>
            <Button variant="secondary" onClick={() => fileInputRef.current.click()}>Upload CSV</Button>
            <Button variant="secondary" onClick={handleExportProducts}>Export Products</Button>
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
                title={isEditing ? "Edit Product" : "Add New Product"}
                onSubmit={handleFormSubmit}
                onCancel={isEditing ? handleCancel : null}
                submitLabel={isEditing ? "Update Product" : "Save Product"}
              >
                <div className={`product-layout-split ${!settings.variantsEnabled ? 'full-width' : ''}`}>
                  {/* Left Column: Add New Product fields */}
                  <div className="product-left-col">
                    <div className="product-form-grid">
                      <div className="image-preview-rect" style={{ height: '100%', minHeight: '120px' }}>
                        {formData.photo ? <img src={formData.photo} alt="Preview" /> : <span style={{ fontSize: '10px', color: 'var(--neutral-400)' }}>No Image</span>}
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

                      <Select label={`Category ${settings.categoryCompulsory ? '*' : ''}`} name="category" value={formData.category} onChange={handleInputChange} options={categoryOptions} error={errors.category} />
                      <Input label="HSN Code" name="hsnCode" value={formData.hsnCode} onChange={handleInputChange} />
                      <Select 
                        label="UOM" 
                        name="uom" 
                        value={formData.uom} 
                        onChange={handleInputChange} 
                        options={(uoms || []).map(u => ({ label: `${u.name} (${u.shortCode})`, value: u.shortCode }))} 
                        error={errors.uom} 
                        required 
                      />
                      
                      {!settings.variantsEnabled && (
                        <>
                          <Input 
                            label="Price" 
                            name="price" 
                            type="number" 
                            value={formData.variants[0].price} 
                            onChange={(e) => handleVariantChange(0, e)} 
                            error={errors['variant_price_0']}
                            required
                          />
                          <Input 
                            label="Initial Stock" 
                            name="stock" 
                            type="number" 
                            value={formData.variants[0].stock} 
                            onChange={(e) => handleVariantChange(0, e)} 
                            error={errors['variant_stock_0']}
                            required
                          />
                        </>
                      )}

                      <Input label="Base Price (Reference)" name="basePrice" type="number" value={formData.basePrice} onChange={handleInputChange} />
                      <ToggleSwitch label="Active Status" name="status" checked={formData.status === 'active'} onChange={handleInputChange} />
                      <div className="form-col-all">
                        <Input label="Description" name="description" value={formData.description} onChange={handleInputChange} />
                      </div>
                    </div>
                  </div>

                  {/* Right Column: Product Variants */}
                  {settings.variantsEnabled && (
                    <div className="product-right-col">
                      <div className="variants-section-split">
                        <div className="section-header-compact">
                          <h3 className="section-title-small">Product Variants</h3>
                          <Button type="button" variant="secondary" onClick={addVariant} style={{ padding: '4px 12px', fontSize: '12px' }}>+ Add Variant</Button>
                        </div>

                        <div className="variants-list">
                          <div style={{ 
                            display: 'grid', 
                            gridTemplateColumns: '2fr 1.2fr 1fr 1fr 0.6fr 40px', 
                            gap: 'var(--spacing-3)', 
                            padding: '0 var(--spacing-3)',
                            marginBottom: '4px' 
                          }}>
                            <span style={{ fontSize: '10px', fontWeight: '700', color: 'var(--neutral-400)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Variant Name</span>
                            <span style={{ fontSize: '10px', fontWeight: '700', color: 'var(--neutral-400)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>SKU</span>
                            <span style={{ fontSize: '10px', fontWeight: '700', color: 'var(--neutral-400)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Price</span>
                            <span style={{ fontSize: '10px', fontWeight: '700', color: 'var(--neutral-400)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Stock</span>
                            <span style={{ fontSize: '10px', fontWeight: '700', color: 'var(--neutral-400)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Status</span>
                            <span></span>
                          </div>
                          {formData.variants.map((v, idx) => (
                            <div key={v.id} className="variant-item-card-split">
                              <Input placeholder="Variant Name" name="name" value={v.name} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_name_${idx}`]} />
                              <Input placeholder="SKU" name="sku" value={v.sku} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_sku_${idx}`]} />
                              <Input placeholder="Price" name="price" type="number" value={v.price} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_price_${idx}`]} />
                              <Input placeholder="Stock" name="stock" type="number" value={v.stock} onChange={(e) => handleVariantChange(idx, e)} error={errors[`variant_stock_${idx}`]} />
                              <ToggleSwitch
                                name="status"
                                checked={v.status === 'active'}
                                onChange={(e) => handleVariantChange(idx, e)}
                              />
                              <button
                                type="button"
                                className="btn-icon-danger"
                                onClick={() => removeVariant(idx)}
                                disabled={formData.variants.length === 1}
                                title="Remove Variant"
                              >
                                🗑
                              </button>
                            </div>
                          ))}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </FormWrapper>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="card">
          <div style={{ marginBottom: 'var(--spacing-4)' }}>
            <h3 className="card-title">All Products</h3>
          </div>

          <Table columns={columns} data={tableData} />
        </div>
      </div>
      <ConfirmDialog
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={() => deleteProduct(productToDelete)}
        title="Delete Product"
        message="Are you sure you want to permanently delete this product? This action cannot be undone."
      />
    </PageContainer>
  );
};

export default Products;
