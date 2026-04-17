import React, { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Button from '../../components/common/Button';
import ToggleSwitch from '../../components/common/ToggleSwitch';
import ConfirmModal from '../../components/common/ConfirmModal';
import BusinessQR from '../../components/common/BusinessQR';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';

const Settings = () => {
  const { user, switchBusiness } = useAuth();
  const { settings, updateSettings, businesses, addBusiness, deleteBusiness } = useDataContext();
  const isAdmin = user?.role === 'Admin';
  
  const [activeTab, setActiveTab] = useState('profile'); // 'profile' | 'business'
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [bizToDelete, setBizToDelete] = useState(null);
  const [newBizData, setNewBizData] = useState({
    businessName: '',
    gstNumber: '',
    phone: '',
    address: '',
    photo: ''
  });
  const [bizErrors, setBizErrors] = useState({});
  const [formData, setFormData] = useState({
    businessName: '',
    gstNumber: '',
    phone: '',
    address: '',
    taxPercentage: '',
    gstPercentage: '',
    currency: 'INR',
    invoicePrefix: 'INV',
    startingNumber: '1',
    footerNote: '',
    invoiceFormat: 'thermal',
    photo: '',
    categoryCompulsory: true,
    variantsEnabled: true
  });

  useEffect(() => {
    if (settings) {
      setFormData(prev => ({ ...prev, ...settings }));
    }
  }, [settings]);

  const [errors, setErrors] = useState({});

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    const val = type === 'checkbox' ? checked : value;
    setFormData(prev => ({ ...prev, [name]: val }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handleFileChange = async (e) => {
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

  const handleBizFileChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const error = validateImage(file);
    if (error) {
      setBizErrors(prev => ({ ...prev, photo: error }));
      return;
    }

    try {
      const base64 = await fileToBase64(file);
      setNewBizData(prev => ({ ...prev, photo: base64 }));
      setBizErrors(prev => ({ ...prev, photo: '' }));
    } catch (err) {
      setBizErrors(prev => ({ ...prev, photo: 'Error processing image.' }));
    }
  };

  const validateForm = () => {
    const newErrors = {};
    if (!formData.businessName.trim()) newErrors.businessName = 'Business name is required';
    if (!formData.phone.trim() || !/^\d{10}$/.test(formData.phone)) newErrors.phone = 'Valid 10-digit phone required';
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = (e) => {
    if (e && e.preventDefault) e.preventDefault();
    if (!validateForm()) return;
    
    // Simulating FormData submission as per user request
    const mockFormData = new FormData();
    Object.keys(formData).forEach(key => {
      mockFormData.append(key, formData[key]);
    });

    updateSettings(formData);
  };

  return (
    <PageContainer title="Business Settings">
      <div className="animate-fade-in">
        {isAdmin && (
          <div className="tabs-container mb-8">
            <button 
              className={`tab-btn ${activeTab === 'profile' ? 'active' : ''}`}
              onClick={() => setActiveTab('profile')}
            >
              General Settings
            </button>
            <button 
              className={`tab-btn ${activeTab === 'business' ? 'active' : ''}`}
              onClick={() => setActiveTab('business')}
            >
              Manage Businesses
            </button>
          </div>
        )}

        {activeTab === 'profile' ? (
          <form onSubmit={handleSave}>
          <div className="settings-layout">
            {/* Left Column: Business & Tax */}
            <div className="settings-column">
              <div className="card mb-6">
                <h3 className="card-title" style={{ marginBottom: 'var(--spacing-6)' }}>Business Information</h3>
                <div className="settings-group">
                  <div className="image-upload-wrapper">
                    <div className={`image-preview-circle ${errors.photo ? 'has-error' : ''}`}>
                      {formData.photo ? (
                        <img src={formData.photo} alt="Business Logo" />
                      ) : (
                        <span style={{ fontSize: '12px', color: 'var(--neutral-400)' }}>Logo</span>
                      )}
                    </div>
                    <div className="upload-field-container">
                      <Input 
                        label="Business Logo"
                        name="photo"
                        type="file"
                        accept="image/*"
                        onChange={handleFileChange}
                        error={errors.photo}
                        className="mb-0"
                      />
                      <p className="upload-hint">Square logo recommended (Max 2MB)</p>
                    </div>
                  </div>
                  <Input 
                    label="Business Name" 
                    name="businessName" 
                    value={formData.businessName} 
                    onChange={handleInputChange} 
                    error={errors.businessName} 
                    required 
                  />
                  <Input 
                    label="GST Number" 
                    name="gstNumber" 
                    value={formData.gstNumber} 
                    onChange={handleInputChange} 
                    error={errors.gstNumber} 
                  />
                  <Input 
                    label="Phone Number" 
                    name="phone" 
                    value={formData.phone} 
                    onChange={handleInputChange} 
                    error={errors.phone} 
                    required 
                  />
                  <Input 
                    label="Business Address" 
                    name="address" 
                    value={formData.address} 
                    onChange={handleInputChange} 
                  />
                </div>
              </div>

              <div className="card mb-6">
                <h3 className="card-title mb-4">Business Profile QR</h3>
                <div style={{ display: 'flex', justifyContent: 'center' }}>
                  <BusinessQR />
                </div>
                <p className="upload-hint mt-4 text-center">Scan to share your business card digitally.</p>
              </div>

              <div className="card">
                <h3 className="card-title mb-4">Tax & Currency</h3>
                <div className="settings-grid-2">
                  <Input 
                    label="Basic Tax (%)" 
                    name="taxPercentage" 
                    type="number" 
                    value={formData.taxPercentage} 
                    onChange={handleInputChange} 
                  />
                  <Input 
                    label="GST (%)" 
                    name="gstPercentage" 
                    type="number" 
                    value={formData.gstPercentage} 
                    onChange={handleInputChange} 
                  />
                  <Select 
                    label="Primary Currency" 
                    name="currency" 
                    value={formData.currency} 
                    onChange={handleInputChange}
                    options={[
                      { label: 'INR (₹)', value: 'INR' },
                      { label: 'USD ($)', value: 'USD' },
                      { label: 'EUR (€)', value: 'EUR' }
                    ]}
                  />
                </div>
              </div>
            </div>

            {/* Right Column: Invoice & Print */}
            <div className="settings-column">
              <div className="card mb-6">
                <h3 className="card-title mb-4">Invoice Configuration</h3>
                <div className="settings-group">
                  <div className="settings-grid-2">
                    <Input 
                      label="Invoice Prefix" 
                      name="invoicePrefix" 
                      value={formData.invoicePrefix} 
                      onChange={handleInputChange} 
                    />
                    <Input 
                      label="Starting Number" 
                      name="startingNumber" 
                      type="number" 
                      value={formData.startingNumber} 
                      onChange={handleInputChange} 
                    />
                  </div>
                  <div className="input-group">
                    <label className="label">Footer Note</label>
                    <textarea 
                      name="footerNote" 
                      className="textarea" 
                      rows="3" 
                      value={formData.footerNote} 
                      onChange={handleInputChange}
                      placeholder="Enter note displayed at the bottom of invoices..."
                    ></textarea>
                  </div>
                </div>
              </div>

              <div className="card">
                <h3 className="card-title mb-4">Printing Preferences</h3>
                <div className="print-settings">
                  <Select 
                    label="Invoice Printing Format" 
                    name="invoiceFormat" 
                    value={formData.invoiceFormat} 
                    onChange={handleInputChange} 
                    options={[
                      { label: 'Thermal Roll (80mm)', value: 'thermal' },
                      { label: 'A4 Full Sheet', value: 'a4' }
                    ]} 
                  />
                  <p className="upload-hint mt-2">Choose the layout that matches your printer type.</p>
                </div>
              </div>

              <div className="card mt-6">
                <h3 className="card-title mb-4">Product Configurations</h3>
                <div className="settings-group">
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--spacing-4)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <span style={{ fontWeight: '600', display: 'block' }}>Mandatory Category</span>
                        <span style={{ fontSize: '12px', color: 'var(--neutral-500)' }}>Require a category for every product</span>
                      </div>
                      <ToggleSwitch 
                        name="categoryCompulsory" 
                        checked={formData.categoryCompulsory} 
                        onChange={handleInputChange} 
                      />
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <span style={{ fontWeight: '600', display: 'block' }}>Product Variants</span>
                        <span style={{ fontSize: '12px', color: 'var(--neutral-500)' }}>Enable multiple sizes/colors per product</span>
                      </div>
                      <ToggleSwitch 
                        name="variantsEnabled" 
                        checked={formData.variantsEnabled} 
                        onChange={handleInputChange} 
                      />
                    </div>
                  </div>
                </div>
              </div>

              <div className="settings-actions mt-8">
                <Button variant="primary" type="submit" style={{width: '100%', padding: 'var(--spacing-4)', fontSize: '1rem'}}>
                  Save All Settings
                </Button>
              </div>
            </div>
          </div>
        </form>
        ) : (
          <div className="business-management-section animate-fade-in">
            <div className="card mb-8">
              <h3 className="card-title mb-6">Add New Business</h3>
              
              <div className="settings-group">
                <div className="image-upload-wrapper mb-6">
                  <div className={`image-preview-circle ${bizErrors.photo ? 'has-error' : ''}`}>
                    {newBizData.photo ? (
                      <img src={newBizData.photo} alt="New Business Logo" />
                    ) : (
                      <span style={{ fontSize: '12px', color: 'var(--neutral-400)' }}>Logo</span>
                    )}
                  </div>
                  <div className="upload-field-container">
                    <Input 
                      label="Business Logo"
                      name="photo"
                      type="file"
                      accept="image/*"
                      onChange={handleBizFileChange}
                      error={bizErrors.photo}
                      className="mb-0"
                    />
                  </div>
                </div>

                <div className="settings-grid-2">
                  <Input 
                    label="Business Name *" 
                    placeholder="e.g. Branch 2, Retail Store" 
                    value={newBizData.businessName}
                    onChange={(e) => setNewBizData(prev => ({ ...prev, businessName: e.target.value }))}
                    error={bizErrors.businessName}
                  />
                  <Input 
                    label="GST Number (Optional)" 
                    placeholder="27AAAAA0000A1Z5" 
                    value={newBizData.gstNumber}
                    onChange={(e) => setNewBizData(prev => ({ ...prev, gstNumber: e.target.value }))}
                  />
                  <Input 
                    label="Phone Number *" 
                    placeholder="9876543210" 
                    value={newBizData.phone}
                    onChange={(e) => setNewBizData(prev => ({ ...prev, phone: e.target.value }))}
                    error={bizErrors.phone}
                  />
                  <Input 
                    label="Business Address" 
                    placeholder="Enter full address" 
                    value={newBizData.address}
                    onChange={(e) => setNewBizData(prev => ({ ...prev, address: e.target.value }))}
                  />
                </div>

                <div className="mt-6">
                  <Button 
                    variant="primary" 
                    style={{ width: '100%' }}
                    onClick={async () => {
                      const errors = {};
                      if (!newBizData.businessName.trim()) errors.businessName = 'Name is required';
                      if (!newBizData.phone.trim() || !/^\d{10}$/.test(newBizData.phone)) errors.phone = 'Valid 10-digit phone required';
                      
                      if (Object.keys(errors).length > 0) {
                        setBizErrors(errors);
                        return;
                      }

                      const success = await addBusiness(newBizData);
                      if (success) {
                        setNewBizData({
                          businessName: '',
                          gstNumber: '',
                          phone: '',
                          address: '',
                          photo: ''
                        });
                        setBizErrors({});
                      }
                    }}
                  >
                    Create Business Entity
                  </Button>
                </div>
              </div>
            </div>

            <div className="card">
              <h3 className="card-title mb-6">Your Businesses</h3>
              <div className="business-list">
                {businesses.map(biz => (
                  <div key={biz.id} className="toggle-item" style={{ marginBottom: 'var(--spacing-4)', background: user?.businessId === biz.id ? 'var(--primary-50)' : '#f9fafb', padding: 'var(--spacing-4)', borderRadius: 'var(--radius-lg)' }}>
                    <div className="toggle-info">
                      <span className="toggle-label">{biz.name}</span>
                      <span className="toggle-desc">{biz.address || 'No address provided'} {user?.businessId === biz.id ? '(Active)' : ''}</span>
                    </div>
                    <div style={{ display: 'flex', gap: 'var(--spacing-2)' }}>
                      {user?.businessId !== biz.id ? (
                        <>
                          <Button variant="secondary" onClick={() => switchBusiness(biz.id)}>
                            Switch
                          </Button>
                          <Button variant="danger" onClick={() => {
                            setBizToDelete(biz);
                            setShowDeleteModal(true);
                          }}>
                            Delete
                          </Button>
                        </>
                      ) : (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--spacing-4)' }}>
                          <span className="text-primary" style={{ fontWeight: '600', fontSize: '14px' }}>Currently Active</span>
                          {businesses.length > 1 && (
                            <Button variant="danger" onClick={() => {
                              setBizToDelete(biz);
                              setShowDeleteModal(true);
                            }}>
                              Delete
                            </Button>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <ConfirmModal 
              isOpen={showDeleteModal}
              onClose={() => setShowDeleteModal(false)}
              onConfirm={() => {
                if (bizToDelete) {
                  deleteBusiness(bizToDelete.id);
                  setBizToDelete(null);
                }
              }}
              title="Delete Business Entity"
              message={`Are you sure you want to delete "${bizToDelete?.name}"? This will permanently remove all related products, transactions, and settings. This action cannot be undone.`}
              confirmText="Delete Everything"
              type="danger"
            />
          </div>
        )}
      </div>
    </PageContainer>
  );
};

export default Settings;
