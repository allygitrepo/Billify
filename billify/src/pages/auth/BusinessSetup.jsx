import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';
import Select from '../../components/common/Select';
import { useAuth } from '../../hooks/useAuth';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';
import { motion } from 'framer-motion';
import { Building, MapPin, Phone, CreditCard, CheckCircle } from 'lucide-react';
import Logo from '../../components/common/Logo';
import api from '../../services/api';

const BusinessSetup = () => {
  const navigate = useNavigate();
  const { user, refreshUser } = useAuth();
  
  const [formData, setFormData] = useState({
    businessName: '',
    gstNumber: '',
    phone: '',
    address: '',
    taxPercentage: '0',
    gstPercentage: '0',
    currency: 'INR',
    invoicePrefix: 'INV',
    startingNumber: '101',
    footerNote: '',
    invoiceFormat: 'thermal',
    businessPhoto: ''
  });

  const [errors, setErrors] = useState({});
  const [isLoading, setIsLoading] = useState(false);
  const [setupError, setSetupError] = useState('');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) setErrors(prev => ({ ...prev, [name]: null }));
  };

  const handleFileChange = async (e, type) => {
    const file = e.target.files[0];
    if (!file) return;

    const error = validateImage(file);
    if (error) {
       setErrors(prev => ({ ...prev, [type]: error }));
       return;
    }

    try {
      const base64 = await fileToBase64(file);
      setFormData(prev => ({ ...prev, [type]: base64 }));
      setErrors(prev => ({ ...prev, [type]: '' }));
    } catch (err) {
      setErrors(prev => ({ ...prev, [type]: 'Error processing image.' }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSetupError('');
    
    if (!formData.businessName.trim()) {
      setErrors({ businessName: 'Business name is required' });
      return;
    }

    setIsLoading(true);
    
    try {
      const response = await api.post('/businesses', {
        businessName: formData.businessName,
        phone: formData.phone,
        gstin: formData.gstNumber,
        address: formData.address,
        photo: formData.businessPhoto,
        taxPercentage: parseFloat(formData.taxPercentage),
        gstPercentage: parseFloat(formData.gstPercentage),
        invoicePrefix: formData.invoicePrefix
      });

      if (response.data.business) {
        // Update local user context with new business
        const newBusiness = response.data.business;
        const updatedBusinesses = [...(user.businesses || []), newBusiness];
        
        refreshUser({
          businesses: updatedBusinesses,
          businessId: newBusiness.id,
          role: newBusiness.role || 'Admin'
        });

        // Store active business context
        localStorage.setItem('business_id', newBusiness.id);
        localStorage.setItem('business_name', newBusiness.name);
        localStorage.setItem('last_business_id', newBusiness.id);

        navigate('/dashboard');
      }
    } catch (error) {
      setIsLoading(false);
      setSetupError(error.response?.data?.message || 'Failed to create business. Please try again.');
    }
  };

  return (
    <div className="auth-layout">
      <div className="auth-container">
        
        {/* Left Branding */}
        <div className="auth-branding">
          <div className="auth-logo-link">
             <Logo size="lg" />
          </div>
          
          <div className="branding-content">
            <motion.div
              initial={{ opacity: 0, x: -30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5 }}
            >
              <div style={{ marginBottom: 'var(--spacing-8)' }}>
                 <Building size={48} strokeWidth={1.5} />
              </div>
              <h1>Welcome, {user?.name?.split(' ')[0]}!</h1>
              <p>One last step to get started. Tell us about your business so we can set up your billing profile.</p>
              
              <div className="features-list mt-8">
                <div className="feature-item flex items-center mb-4">
                  <CheckCircle size={20} className="text-teal-400 mr-3" />
                  <span>Custom Invoice Branding</span>
                </div>
                <div className="feature-item flex items-center mb-4">
                  <CheckCircle size={20} className="text-teal-400 mr-3" />
                  <span>GST & Tax Management</span>
                </div>
              </div>
            </motion.div>
          </div>

          <div className="branding-footer">
            <p>© 2026 Self Billing POS Systems.</p>
          </div>
        </div>

        {/* Right Form */}
        <div className="auth-form-container">
          <motion.div 
            className="auth-card" 
            style={{ maxWidth: '640px' }}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
          >
            <div className="auth-header">
              <h2>Setup Your Business</h2>
              <p>Configure your workspace and billing defaults.</p>
            </div>

            {setupError && (
              <div className="error-alert mb-8" style={{ padding: 'var(--spacing-4)', backgroundColor: '#fef2f2', color: '#dc2626', borderRadius: '12px', textAlign: 'center', border: '1px solid #fee2e2' }}>
                {setupError}
              </div>
            )}

            <form onSubmit={handleSubmit} className="login-form">
              <div className="image-upload-wrapper mb-8">
                <div style={{ 
                  width: '72px', 
                  height: '72px', 
                  borderRadius: '12px', 
                  backgroundColor: 'white', 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  overflow: 'hidden', 
                  border: '2px solid white',
                  boxShadow: 'var(--shadow-sm)'
                }}>
                  {formData.businessPhoto ? (
                    <img src={formData.businessPhoto} alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                  ) : (
                    <Building size={32} color="var(--neutral-300)" />
                  )}
                </div>
                <div style={{ flex: 1, marginLeft: 'var(--spacing-6)' }}>
                   <label style={{ fontSize: '0.875rem', fontWeight: '700', color: 'var(--neutral-700)', display: 'block', marginBottom: '4px' }}>Business Logo</label>
                   <input 
                     type="file" 
                     id="bizPhotoInput"
                     accept="image/*" 
                     onChange={(e) => handleFileChange(e, 'businessPhoto')} 
                     style={{ display: 'none' }}
                   />
                   <button 
                     type="button" 
                     onClick={() => document.getElementById('bizPhotoInput').click()}
                     style={{ fontSize: '0.825rem', color: 'var(--primary-600)', background: 'none', border: 'none', padding: 0, fontWeight: '700', cursor: 'pointer', textDecoration: 'underline' }}
                   >
                     {formData.businessPhoto ? 'Change Logo' : 'Upload Brand Logo'}
                   </button>
                </div>
              </div>

              <div className="settings-grid-2">
                <Input 
                  label="Business Name" 
                  name="businessName" 
                  placeholder="e.g. Acme Retailers"
                  value={formData.businessName} 
                  onChange={handleChange} 
                  error={errors.businessName} 
                  required 
                />
                <Input 
                  label="Business Phone" 
                  name="phone" 
                  placeholder="00000 00000"
                  value={formData.phone} 
                  onChange={handleChange} 
                />
                <Input 
                  label="GSTIN" 
                  name="gstNumber" 
                  placeholder="GST Number (Optional)"
                  value={formData.gstNumber} 
                  onChange={handleChange} 
                />
                <Input 
                  label="Address" 
                  name="address" 
                  placeholder="City, State, Country"
                  value={formData.address} 
                  onChange={handleChange} 
                />
              </div>

              <div className="settings-grid-2 mt-4">
                <Input label="Default Tax (%)" name="taxPercentage" type="number" value={formData.taxPercentage} onChange={handleChange} />
                <Input label="Default GST (%)" name="gstPercentage" type="number" value={formData.gstPercentage} onChange={handleChange} />
              </div>
              
              <div className="settings-grid-2 mt-4">
                <Select 
                  label="Invoice Format" 
                  name="invoiceFormat" 
                  value={formData.invoiceFormat} 
                  onChange={handleChange} 
                  options={[
                    {label: 'Thermal (58/80mm)', value: 'thermal'}, 
                    {label: 'A4 Page', value: 'a4'}
                  ]} 
                />
                <Input label="Invoice Prefix" name="invoicePrefix" value={formData.invoicePrefix} onChange={handleChange} />
              </div>

              <Button 
                type="submit"
                variant="primary" 
                isLoading={isLoading} 
                className="w-full mt-8"
                style={{ height: '52px', borderRadius: '12px', fontWeight: '700', fontSize: '1rem' }}
              >
                Create Business & Start
              </Button>
            </form>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

export default BusinessSetup;
