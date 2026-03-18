import React, { useState, useEffect } from 'react';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Button from '../../components/common/Button';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';

const Settings = () => {
  const { settings, updateSettings } = useDataContext();
  const [formData, setFormData] = useState({
    businessName: '',
    gstNumber: '',
    phone: '',
    address: '',
    taxPercentage: '',
    gstPercentage: '',
    currency: 'INR',
    invoicePrefix: 'INV',
    startingNumber: '1001',
    footerNote: '',
    thermalPrint: true,
    a4Print: false,
    photo: ''
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

  const validateForm = () => {
    const newErrors = {};
    if (!formData.businessName.trim()) newErrors.businessName = 'Business name is required';
    if (!formData.gstNumber.trim()) newErrors.gstNumber = 'GST Number is required';
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
    alert('Settings saved successfully!');
  };

  return (
    <PageContainer title="Business Settings">
      <div className="animate-fade-in">
        <form onSubmit={handleSave}>
          <div className="settings-layout">
            {/* Left Column: Business & Tax */}
            <div className="settings-column">
              <div className="card mb-6">
                <div className="settings-header-with-avatar">
                  <h3 className="card-title">Business Information</h3>
                  <div className={`image-preview-circle ${errors.photo ? 'has-error' : ''}`}>
                    {formData.photo ? (
                      <img src={formData.photo} alt="Business Logo" />
                    ) : (
                      <span style={{ fontSize: '12px', color: 'var(--neutral-400)' }}>Logo</span>
                    )}
                  </div>
                </div>
                <div className="settings-group">
                  <div className="image-upload-wrapper">
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
                    required 
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
                  <div style={{marginTop: 'var(--spacing-4)'}}>
                    <label className="input-label">Footer Note</label>
                    <textarea 
                      name="footerNote" 
                      className="custom-textarea" 
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
                  <label className="toggle-item">
                    <div className="toggle-info">
                      <span className="toggle-label">Thermal Printing</span>
                      <span className="toggle-desc">Enable 80mm/58mm roll printing</span>
                    </div>
                    <input 
                      type="checkbox" 
                      name="thermalPrint" 
                      checked={formData.thermalPrint} 
                      onChange={handleInputChange} 
                      className="toggle-checkbox"
                    />
                  </label>

                  <label className="toggle-item">
                    <div className="toggle-info">
                      <span className="toggle-label">A4 Full Sheet Printing</span>
                      <span className="toggle-desc">Generate invoices in A4 PDF format</span>
                    </div>
                    <input 
                      type="checkbox" 
                      name="a4Print" 
                      checked={formData.a4Print} 
                      onChange={handleInputChange} 
                      className="toggle-checkbox"
                    />
                  </label>
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
      </div>
    </PageContainer>
  );
};

export default Settings;
