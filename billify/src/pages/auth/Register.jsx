import React, { useState } from 'react';
import { useNavigate, NavLink } from 'react-router-dom';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';
import Select from '../../components/common/Select';
import { validateEmail, validatePassword, validate } from '../../utils/validators';
import { useAuth } from '../../hooks/useAuth';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';
import { motion, AnimatePresence } from 'framer-motion';
import { Eye, EyeOff, User, Building, MapPin, Phone, CreditCard, ChevronRight, ArrowLeft } from 'lucide-react';
import Logo from '../../components/common/Logo';

const Register = () => {
  const navigate = useNavigate();
  const { register } = useAuth();
  
  const [step, setStep] = useState(1);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const [formData, setFormData] = useState({
    // Step 1: User
    username: '',
    email: '',
    password: '',
    confirmPassword: '',
    userPhoto: '',
    userMobile: '',
    
    // Step 2: Business
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
  const [registerError, setRegisterError] = useState('');

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

  const nextStep = () => {
    const stepErrors = {};
    if (step === 1) {
      if (!formData.username.trim()) stepErrors.username = 'Username is required';
      const emailError = validateEmail(formData.email);
      if (emailError) stepErrors.email = emailError;
      const passError = validatePassword(formData.password);
      if (passError) stepErrors.password = passError;
      if (formData.password !== formData.confirmPassword) stepErrors.confirmPassword = 'Passwords do not match';
    }
    
    if (Object.keys(stepErrors).length > 0) {
      setErrors(stepErrors);
      return;
    }
    setStep(2);
  };

  const prevStep = () => setStep(1);

  const handleSubmit = async (e) => {
    if (e) e.preventDefault();
    setRegisterError('');
    
    const bizErrors = {};
    if (!formData.businessName.trim()) bizErrors.businessName = 'Business name is required';
    if (!formData.phone.trim() || !/^\d{10}$/.test(formData.phone)) bizErrors.phone = 'Valid 10-digit phone number is required';
    
    if (Object.keys(bizErrors).length > 0) {
      setErrors(bizErrors);
      return;
    }

    setIsLoading(true);
    
    try {
      const result = await register(formData);
      
      if (result.success) {
        // Since the server register returns user info but no session token,
        // we redirect to login to ensure proper session establishment.
        navigate('/login', { state: { message: 'Registration successful! Please login.' } });
      } else {
        setIsLoading(false);
        setRegisterError(result.message);
      }
    } catch (error) {
      setIsLoading(false);
      setRegisterError(error.message || 'An unexpected error occurred.');
    }
  };

  return (
    <div className="auth-layout">
      <div className="auth-container">
        
        {/* Left Branding Content */}
        <div className="auth-branding">
          <NavLink to="/" className="auth-logo-link">
             <Logo size="lg" />
          </NavLink>
          
          <div className="branding-content">
            <AnimatePresence mode="wait">
              <motion.div
                key={step}
                initial={{ opacity: 0, x: -30 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: 30 }}
                transition={{ duration: 0.4, ease: 'easeOut' }}
              >
                <div style={{ marginBottom: 'var(--spacing-8)' }}>
                   {step === 1 ? <User size={48} strokeWidth={1.5} /> : <Building size={48} strokeWidth={1.5} />}
                </div>
                <h1>
                  {step === 1 ? 'Join the next generation of retailers.' : 'Establish your business brand.'}
                </h1>
                <p>
                  {step === 1 
                    ? 'Start with a single dashboard to manage every aspect of your business, from inventory to sales.' 
                    : 'Your professional profile helps customers identify you across invoices and receipts.'}
                </p>
              </motion.div>
            </AnimatePresence>
          </div>

          <div className="branding-footer">
            <p>© 2026 Billify POS Systems. All rights reserved.</p>
          </div>
        </div>

        {/* Right Form Content */}
        <div className="auth-form-container">
          <div className="auth-card" style={{ maxWidth: step === 1 ? '420px' : '640px' }}>
            
            <div className="auth-header">
              <div className="step-progress-wrapper">
                <div style={{ flex: 1, position: 'relative' }}>
                   <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '36px', height: '36px', borderRadius: '10px', backgroundColor: step >= 1 ? 'var(--primary-600)' : 'var(--neutral-100)', color: step >= 1 ? 'white' : 'var(--neutral-400)', fontWeight: '700', fontSize: '14px', zIndex: 1, position: 'relative' }}>1</div>
                   <span style={{ position: 'absolute', top: '44px', left: '0', whiteSpace: 'nowrap', fontSize: '11px', fontWeight: '700', color: step === 1 ? 'var(--primary-600)' : 'var(--neutral-400)', letterSpacing: '0.05em' }}>REGISTRATION</span>
                </div>
                <div style={{ flex: 2, height: '4px', backgroundColor: step >= 2 ? 'var(--primary-600)' : 'var(--neutral-100)', borderRadius: '2px' }}></div>
                <div style={{ flex: 1, position: 'relative', display: 'flex', justifyContent: 'flex-end' }}>
                   <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '36px', height: '36px', borderRadius: '10px', backgroundColor: step >= 2 ? 'var(--primary-600)' : 'var(--neutral-100)', color: step >= 2 ? 'white' : 'var(--neutral-400)', fontWeight: '700', fontSize: '14px', zIndex: 1, position: 'relative' }}>2</div>
                   <span style={{ position: 'absolute', top: '44px', right: '0', whiteSpace: 'nowrap', fontSize: '11px', fontWeight: '700', color: step === 2 ? 'var(--primary-600)' : 'var(--neutral-400)', letterSpacing: '0.05em' }}>BUSINESS PROFILE</span>
                </div>
              </div>
              <h2>{step === 1 ? 'Account Registration' : 'Business Essentials'}</h2>
              <p>{step === 1 ? 'Fill in your primary account credentials.' : 'Set up your business identity and billing defaults.'}</p>
            </div>

            {registerError && (
              <motion.div 
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="error-alert mb-8" 
                style={{ padding: 'var(--spacing-4)', backgroundColor: '#fef2f2', color: '#dc2626', borderRadius: '12px', textAlign: 'center', border: '1px solid #fee2e2', fontWeight: '600', fontSize: '0.925rem' }}
              >
                {registerError}
              </motion.div>
            )}

            <AnimatePresence mode="wait">
              {step === 1 ? (
                <motion.div
                  key="step1"
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -15 }}
                  transition={{ duration: 0.3 }}
                >
                  <div className="login-form">
                    <div className="image-upload-wrapper mb-8">
                      <div style={{ 
                        width: '72px', 
                        height: '72px', 
                        borderRadius: '50%', 
                        backgroundColor: 'white', 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center', 
                        overflow: 'hidden', 
                        border: '2px solid white',
                        boxShadow: 'var(--shadow-sm)'
                      }}>
                        {formData.userPhoto ? (
                          <img src={formData.userPhoto} alt="User" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        ) : (
                          <User size={32} color="var(--neutral-300)" />
                        )}
                      </div>
                      <div style={{ flex: 1, marginLeft: 'var(--spacing-6)' }}>
                         <label style={{ fontSize: '0.875rem', fontWeight: '700', color: 'var(--neutral-700)', display: 'block', marginBottom: '4px' }}>Profile Avatar</label>
                         <input 
                           type="file" 
                           id="userPhotoInput"
                           accept="image/*" 
                           onChange={(e) => handleFileChange(e, 'userPhoto')} 
                           style={{ display: 'none' }}
                         />
                         <button 
                           type="button" 
                           onClick={() => document.getElementById('userPhotoInput').click()}
                           style={{ fontSize: '0.825rem', color: 'var(--primary-600)', background: 'none', border: 'none', padding: 0, fontWeight: '700', cursor: 'pointer', textDecoration: 'underline' }}
                         >
                           {formData.userPhoto ? 'Change Photo' : 'Upload Image'}
                         </button>
                      </div>
                    </div>
                    
                    <Input 
                      label="Username / Full Name" 
                      name="username" 
                      placeholder="e.g. John Doe"
                      value={formData.username} 
                      onChange={handleChange} 
                      error={errors.username} 
                      required 
                    />
                    <Input 
                      label="Email Address" 
                      name="email" 
                      type="email" 
                      placeholder="john@example.com"
                      value={formData.email} 
                      onChange={handleChange} 
                      error={errors.email} 
                      required 
                    />
                    
                    <Input 
                      label="Mobile Number" 
                      name="userMobile" 
                      placeholder="e.g. 9876543210"
                      value={formData.userMobile} 
                      onChange={handleChange} 
                      error={errors.userMobile} 
                      icon={<Phone size={18} />}
                      required 
                    />
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--spacing-6)' }}>
                      <Input 
                        label="Password" 
                        name="password" 
                        type={showPassword ? 'text' : 'password'} 
                        placeholder="••••••••"
                        value={formData.password} 
                        onChange={handleChange} 
                        error={errors.password} 
                        endIcon={showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                        onIconClick={() => setShowPassword(!showPassword)}
                        required 
                      />
                      <Input 
                        label="Confirm" 
                        name="confirmPassword" 
                        type={showConfirmPassword ? 'text' : 'password'} 
                        placeholder="••••••••"
                        value={formData.confirmPassword} 
                        onChange={handleChange} 
                        error={errors.confirmPassword} 
                        endIcon={showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                        onIconClick={() => setShowConfirmPassword(!showConfirmPassword)}
                        required 
                      />
                    </div>

                    <Button variant="primary" className="w-full mt-4" onClick={nextStep} style={{ height: '52px', fontSize: '1rem', fontWeight: '700', borderRadius: '12px' }}>
                      Continue to Business Setup <ChevronRight size={18} style={{ marginLeft: '8px' }} />
                    </Button>
                  </div>
                </motion.div>
              ) : (
                <motion.div
                  key="step2"
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -15 }}
                  transition={{ duration: 0.3 }}
                >
                  <div className="login-form">
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
                           {formData.businessPhoto ? 'Change Logo' : 'Set Brand Logo'}
                         </button>
                      </div>
                    </div>

                    <div className="settings-grid-2">
                      <Input 
                        label="Business Name" 
                        name="businessName" 
                        placeholder="Acme HQ"
                        value={formData.businessName} 
                        onChange={handleChange} 
                        error={errors.businessName} 
                        required 
                      />
                      <Input 
                        label="Phone" 
                        name="phone" 
                        placeholder="9876543210"
                        value={formData.phone} 
                        onChange={handleChange} 
                        error={errors.phone} 
                        required 
                      />
                      <Input 
                        label="GSTIN" 
                        name="gstNumber" 
                        placeholder="GST (Optional)"
                        value={formData.gstNumber} 
                        onChange={handleChange} 
                      />
                      <Input 
                        label="Address" 
                        name="address" 
                        placeholder="Street, City, State"
                        value={formData.address} 
                        onChange={handleChange} 
                      />
                    </div>

                    <div className="settings-grid-2 mt-4">
                      <Input label="Tax (%)" name="taxPercentage" type="number" value={formData.taxPercentage} onChange={handleChange} />
                      <Input label="GST (%)" name="gstPercentage" type="number" value={formData.gstPercentage} onChange={handleChange} />
                    </div>
                    
                    <div className="settings-grid-2 mt-4">
                      <Select 
                        label="Printing Size" 
                        name="invoiceFormat" 
                        value={formData.invoiceFormat} 
                        onChange={handleChange} 
                        options={[
                          {label: 'Thermal (58/80mm)', value: 'thermal'}, 
                          {label: 'A4 Page', value: 'a4'}
                        ]} 
                      />
                      <Input label="Inv Prefix" name="invoicePrefix" value={formData.invoicePrefix} onChange={handleChange} />
                    </div>

                    <div style={{ display: 'flex', gap: 'var(--spacing-6)', marginTop: 'var(--spacing-8)' }}>
                      <button 
                        type="button" 
                        onClick={prevStep} 
                        style={{ 
                          flex: 1, 
                          height: '52px', 
                          display: 'flex', 
                          alignItems: 'center', 
                          justifyContent: 'center', 
                          gap: '8px', 
                          backgroundColor: 'white', 
                          border: '1px solid var(--neutral-200)', 
                          borderRadius: '12px', 
                          color: 'var(--neutral-700)', 
                          fontWeight: '700', 
                          cursor: 'pointer' 
                        }}
                      >
                        <ArrowLeft size={18} /> Back
                      </button>
                      <Button 
                        variant="primary" 
                        isLoading={isLoading} 
                        onClick={handleSubmit} 
                        style={{ flex: 2, height: '52px', borderRadius: '12px', fontWeight: '700' }}
                      >
                        Complete & Get Started
                      </Button>
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <div className="auth-footer mt-10" style={{ textAlign: 'center', borderTop: '1px solid var(--neutral-100)', paddingTop: 'var(--spacing-8)' }}>
              <p style={{ color: 'var(--neutral-500)' }}>Already a member? <NavLink to="/login" style={{ color: 'var(--primary-600)', fontWeight: '700', marginLeft: '4px' }}>Login</NavLink></p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Register;
