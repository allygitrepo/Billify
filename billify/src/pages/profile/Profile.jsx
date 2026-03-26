import React, { useState, useRef } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { userService } from '../../services/user.service';
import PageContainer from '../../components/layout/PageContainer';
import { useDataContext } from '../../hooks/useDataContext';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';
import { motion, AnimatePresence } from 'framer-motion';
import { User, Mail, Phone, Shield, Lock, CheckCircle, Camera, Edit2, X, Save } from 'lucide-react';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';

const Profile = () => {
  const { user, refreshUser } = useAuth();
  const { showToast } = useDataContext();
  const fileInputRef = useRef(null);
  
  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  
  // Profile Form State
  const [profileData, setProfileData] = useState({
    name: user?.name || '',
    mobile: user?.mobile || '',
    photo: user?.photo || ''
  });
  const [profileErrors, setProfileErrors] = useState({});

  // Password Form State
  const [passwordFormData, setPasswordFormData] = useState({
    oldPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [passwordErrors, setPasswordErrors] = useState({});

  const handleProfileInputChange = (e) => {
    const { name, value } = e.target;
    setProfileData(prev => ({ ...prev, [name]: value }));
    if (profileErrors[name]) setProfileErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handlePhotoChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const error = validateImage(file);
    if (error) {
      showToast(error, 'error');
      return;
    }

    try {
      const base64 = await fileToBase64(file);
      setProfileData(prev => ({ ...prev, photo: base64 }));
    } catch (err) {
      showToast('Error processing image', 'error');
    }
  };

  const handleUpdateProfile = async () => {
    const errors = {};
    if (!profileData.name.trim()) errors.name = 'Name is required';
    if (Object.keys(errors).length > 0) {
      setProfileErrors(errors);
      return;
    }

    setIsLoading(true);
    try {
      const response = await userService.updateProfile(profileData);
      showToast('Profile updated successfully!', 'success');
      setIsEditing(false);
      // Refresh the user context to reflect changes everywhere (header, etc)
      if (refreshUser) refreshUser(response.user);
    } catch (err) {
      showToast(err.message || 'Failed to update profile', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePasswordInputChange = (e) => {
    const { name, value } = e.target;
    setPasswordFormData(prev => ({ ...prev, [name]: value }));
    if (passwordErrors[name]) setPasswordErrors(prev => ({ ...prev, [name]: '' }));
  };

  const validatePasswordForm = () => {
    const errors = {};
    if (!passwordFormData.oldPassword) errors.oldPassword = 'Current password is required';
    if (!passwordFormData.newPassword) errors.newPassword = 'New password is required';
    if (passwordFormData.newPassword.length < 6) errors.newPassword = 'Password must be at least 6 characters';
    if (passwordFormData.newPassword !== passwordFormData.confirmPassword) {
      errors.confirmPassword = 'Passwords do not match';
    }
    setPasswordErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleChangePassword = async () => {
    if (!validatePasswordForm()) return;

    setIsLoading(true);
    try {
      await userService.changePassword({
        oldPassword: passwordFormData.oldPassword,
        newPassword: passwordFormData.newPassword
      });
      showToast('Password updated successfully!', 'success');
      setPasswordFormData({ oldPassword: '', newPassword: '', confirmPassword: '' });
    } catch (err) {
      showToast(err.message || 'Failed to update password', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <PageContainer title="My Profile">
      <div className="profile-container animate-fade-in">
        <div className="profile-grid">
          {/* Left Column: User Info Card */}
          <div className="profile-info-card card">
            <div className="profile-header">
              <div className="profile-avatar-container">
                <div className="profile-avatar-large">
                  {profileData.photo ? (
                    <img src={profileData.photo} alt={profileData.name} />
                  ) : (
                    <div className="avatar-placeholder">
                      {profileData.name?.charAt(0).toUpperCase()}
                    </div>
                  )}
                </div>
                {isEditing && (
                  <button 
                    className="avatar-edit-btn" 
                    onClick={() => fileInputRef.current.click()}
                    title="Change Photo"
                  >
                    <Camera size={16} />
                  </button>
                )}
                <input 
                  type="file" 
                  ref={fileInputRef} 
                  style={{ display: 'none' }} 
                  accept="image/*"
                  onChange={handlePhotoChange}
                />
              </div>
              
              <div className="profile-title">
                {isEditing ? (
                  <div style={{ marginTop: 'var(--spacing-4)' }}>
                    <Input 
                      placeholder="Your Name" 
                      name="name" 
                      value={profileData.name} 
                      onChange={handleProfileInputChange}
                      error={profileErrors.name}
                      noMargin
                    />
                  </div>
                ) : (
                  <h2>{user?.name}</h2>
                )}
                <div className="role-badge">
                  <Shield size={14} />
                  <span>{user?.businesses?.[0]?.role || 'User'}</span>
                </div>
              </div>

              {!isEditing && (
                <button className="btn-icon-secondary edit-mode-btn" onClick={() => setIsEditing(true)}>
                  <Edit2 size={16} />
                </button>
              )}
            </div>

            <div className="profile-details">
              <div className="detail-item">
                <div className="detail-icon"><Mail size={18} /></div>
                <div className="detail-content">
                  <label>Email Address</label>
                  <p>{user?.email}</p>
                  <small style={{ color: 'var(--neutral-400)', fontSize: '10px' }}>Email cannot be changed</small>
                </div>
              </div>
              
              <div className="detail-item">
                <div className="detail-icon"><Phone size={18} /></div>
                <div className="detail-content" style={{ width: '100%' }}>
                  <label>Mobile Number</label>
                  {isEditing ? (
                    <Input 
                      name="mobile" 
                      value={profileData.mobile} 
                      onChange={handleProfileInputChange} 
                      placeholder="Enter mobile number"
                      noMargin
                    />
                  ) : (
                    <p>{user?.mobile || 'Not provided'}</p>
                  )}
                </div>
              </div>
            </div>

            {isEditing && (
              <div className="profile-actions-footer">
                <Button variant="secondary" onClick={() => {
                  setIsEditing(false);
                  setProfileData({
                    name: user?.name || '',
                    mobile: user?.mobile || '',
                    photo: user?.photo || ''
                  });
                }} disabled={isLoading}>
                  <X size={16} style={{ marginRight: '8px' }} /> Cancel
                </Button>
                <Button variant="primary" onClick={handleUpdateProfile} isLoading={isLoading}>
                  <Save size={16} style={{ marginRight: '8px' }} /> Save Changes
                </Button>
              </div>
            )}
          </div>

          {/* Right Column: Security/Password Card */}
          <div className="profile-security-card card">
            <h3 className="card-title mb-6">Security Settings</h3>
            <p className="text-muted mb-8">Update your password to keep your account secure.</p>
            
            <div className="password-form">
              <Input 
                label="Current Password" 
                name="oldPassword" 
                type="password" 
                value={passwordFormData.oldPassword} 
                onChange={handlePasswordInputChange}
                error={passwordErrors.oldPassword}
                icon={<Lock size={18} />}
                required
              />
              <Input 
                label="New Password" 
                name="newPassword" 
                type="password" 
                value={passwordFormData.newPassword} 
                onChange={handlePasswordInputChange}
                error={passwordErrors.newPassword}
                icon={<Lock size={18} />}
                required
              />
              <Input 
                label="Confirm New Password" 
                name="confirmPassword" 
                type="password" 
                value={passwordFormData.confirmPassword} 
                onChange={handlePasswordInputChange}
                error={passwordErrors.confirmPassword}
                icon={<Lock size={18} />}
                required
              />
              
              <div className="mt-6">
                <Button 
                  variant="primary" 
                  onClick={handleChangePassword} 
                  isLoading={isLoading}
                  fullWidth
                >
                  Change Password
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <style jsx>{`
        .profile-grid {
          display: grid;
          grid-template-columns: 1.2fr 1fr;
          gap: var(--spacing-8);
          align-items: start;
        }

        @media (max-width: 992px) {
          .profile-grid {
            grid-template-columns: 1fr;
          }
        }

        .profile-header {
          display: flex;
          flex-direction: column;
          align-items: center;
          text-align: center;
          margin-bottom: var(--spacing-8);
          padding-bottom: var(--spacing-8);
          border-bottom: 1px solid var(--neutral-100);
          position: relative;
        }

        .edit-mode-btn {
          position: absolute;
          top: 0;
          right: 0;
        }

        .profile-avatar-container {
          position: relative;
          margin-bottom: var(--spacing-4);
        }

        .profile-avatar-large {
          width: 100px;
          height: 100px;
          border-radius: 24px;
          overflow: hidden;
          background: var(--primary-50);
          display: flex;
          align-items: center;
          justify-content: center;
          border: 3px solid white;
          box-shadow: var(--shadow-md);
        }

        .profile-avatar-large img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .avatar-edit-btn {
          position: absolute;
          bottom: -8px;
          right: -8px;
          width: 32px;
          height: 32px;
          border-radius: 50%;
          background: var(--primary-600);
          color: white;
          border: 2px solid white;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          box-shadow: var(--shadow-sm);
        }

        .avatar-placeholder {
          font-size: 2.5rem;
          font-weight: 800;
          color: var(--primary-600);
        }

        .profile-title h2 {
          margin: 0 0 8px 0;
          font-size: 1.75rem;
          color: var(--neutral-900);
        }

        .role-badge {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          background: var(--primary-50);
          color: var(--primary-700);
          padding: 4px 12px;
          border-radius: 100px;
          font-size: 0.75rem;
          font-weight: 700;
          text-transform: uppercase;
        }

        .detail-item {
          display: flex;
          gap: var(--spacing-4);
          margin-bottom: var(--spacing-6);
        }

        .detail-icon {
          width: 40px;
          height: 40px;
          border-radius: 10px;
          background: var(--neutral-50);
          display: flex;
          align-items: center;
          justify-content: center;
          color: var(--neutral-500);
          flex-shrink: 0;
        }

        .detail-content label {
          display: block;
          font-size: 0.75rem;
          color: var(--neutral-400);
          margin-bottom: 2px;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          font-weight: 700;
        }

        .detail-content p {
          margin: 0;
          font-weight: 600;
          color: var(--neutral-800);
        }

        .profile-actions-footer {
          display: flex;
          justify-content: flex-end;
          gap: var(--spacing-3);
          margin-top: var(--spacing-8);
          padding-top: var(--spacing-6);
          border-top: 1px solid var(--neutral-100);
        }

        .text-muted {
          color: var(--neutral-500);
          font-size: 0.875rem;
        }
      `}</style>
    </PageContainer>
  );
};

export default Profile;
