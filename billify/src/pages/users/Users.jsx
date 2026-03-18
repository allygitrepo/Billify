import React, { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import FormWrapper from '../../components/common/FormWrapper';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Button from '../../components/common/Button';
import Table from '../../components/common/Table';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';

const Users = () => {
  const { users, roles, addUser, updateUser, deleteUser, addRole } = useDataContext();

  // Permission Groups
  const permissionGroups = [
    { id: 'products', label: 'Product Management' },
    { id: 'inventory', label: 'Inventory Management' },
    { id: 'billing', label: 'Billing' },
    { id: 'transactions', label: 'Transactions' },
    { id: 'settings', label: 'Settings' }
  ];

  // State
  const [activeForm, setActiveForm] = useState(null); // null | 'user' | 'role'
  const [isEditingUser, setIsEditingUser] = useState(false);
  const [editingUserId, setEditingUserId] = useState(null);
  const [userFormData, setUserFormData] = useState({
    name: '',
    email: '',
    mobile: '',
    role: '',
    status: 'active',
    photo: ''
  });
  const [userErrors, setUserErrors] = useState({});

  const [roleFormData, setRoleFormData] = useState({
    name: '',
    permissions: []
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('All');

  // User Handlers
  const handleUserInputChange = (e) => {
    const { name, value } = e.target;
    setUserFormData(prev => ({ ...prev, [name]: value }));
    if (userErrors[name]) setUserErrors(prev => ({ ...prev, [name]: '' }));
  };

  const handleUserPhotoChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const error = validateImage(file);
    if (error) {
      setUserErrors(prev => ({ ...prev, photo: error }));
      return;
    }

    try {
      const base64 = await fileToBase64(file);
      setUserFormData(prev => ({ ...prev, photo: base64 }));
      setUserErrors(prev => ({ ...prev, photo: '' }));
    } catch (err) {
      setUserErrors(prev => ({ ...prev, photo: 'Error processing image.' }));
    }
  };

  const validateUserForm = () => {
    const errors = {};
    if (!userFormData.name.trim()) errors.name = 'Name is required';
    if (!userFormData.email.trim() || !/\S+@\S+\.\S+/.test(userFormData.email)) errors.email = 'Valid email required';
    if (!userFormData.mobile.trim() || !/^\d{10}$/.test(userFormData.mobile)) errors.mobile = '10-digit mobile required';
    if (!userFormData.role) errors.role = 'Role required';
    setUserErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleUserSubmit = () => {
    if (!validateUserForm()) return;

    // Simulate FormData
    const mockFormData = new FormData();
    Object.keys(userFormData).forEach(key => {
      mockFormData.append(key, userFormData[key]);
    });

    if (isEditingUser) {
      updateUser(editingUserId, userFormData);
      setIsEditingUser(false);
      setEditingUserId(null);
    } else {
      addUser({ ...userFormData, status: 'active' });
    }
    resetUserForm();
  };

  const resetUserForm = () => {
    setUserFormData({ name: '', email: '', mobile: '', role: '', status: 'active', photo: '' });
    setUserErrors({});
    setIsEditingUser(false);
    setActiveForm(null);
  };

  const handleEditUser = (user) => {
    setIsEditingUser(true);
    setEditingUserId(user.id);
    setUserFormData({ ...user });
    setActiveForm('user');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = (id, currentStatus) => {
    updateUser(id, { status: currentStatus === 'active' ? 'inactive' : 'active' });
  };

  // Role Handlers
  const handleRoleInputChange = (e) => {
    setRoleFormData(prev => ({ ...prev, name: e.target.value }));
  };

  const handlePermissionToggle = (permissionId) => {
    setRoleFormData(prev => {
      const isSelected = prev.permissions.includes(permissionId);
      const newPermissions = isSelected 
        ? prev.permissions.filter(p => p !== permissionId)
        : [...prev.permissions, permissionId];
      return { ...prev, permissions: newPermissions };
    });
  };

  const handleRoleSubmit = () => {
    if (!roleFormData.name.trim()) {
      alert('Role name is required');
      return;
    }
    addRole(roleFormData);
    setRoleFormData({ name: '', permissions: [] });
    setActiveForm(null);
  };

  // Filtering
  const filteredUsers = useMemo(() => {
    return users.filter(u => {
      const matchesSearch = u.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
                           u.email.toLowerCase().includes(searchTerm.toLowerCase());
      const matchesRole = roleFilter === 'All' || u.role === roleFilter;
      return matchesSearch && matchesRole;
    });
  }, [users, searchTerm, roleFilter]);

  // Table Columns
  const columns = [
    { 
      key: 'photo', 
      label: 'Avatar',
      render: (val) => (
        <div className="table-avatar">
          {val ? <img src={val} alt="User" /> : null}
        </div>
      )
    },
    { key: 'name', label: 'Name', render: (val) => <span style={{fontWeight: '600'}}>{val}</span> },
    { key: 'email', label: 'Email' },
    { key: 'mobile', label: 'Mobile' },
    { key: 'role', label: 'Role' },
    { 
      key: 'status', 
      label: 'Status',
      render: (val) => (
        <span className={`status-badge ${val}`}>
          {val.charAt(0).toUpperCase() + val.slice(1)}
        </span>
      )
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div style={{display: 'flex', gap: 'var(--spacing-3)'}}>
          <button className="btn-text" onClick={() => handleEditUser(row)} style={{color: 'var(--primary-600)'}}>Edit</button>
          <button className="btn-text" onClick={() => handleToggleStatus(row.id, row.status)} style={{color: row.status === 'active' ? 'var(--danger-500)' : 'var(--success-500)'}}>
            {row.status === 'active' ? 'Deactivate' : 'Activate'}
          </button>
        </div>
      )
    }
  ];

  return (
    <PageContainer 
      title="Users & Roles Management"
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-4)', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          <div className="filters-row" style={{ maxWidth: '400px', margin: 0 }}>
            <Input
              placeholder="Search users..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <Select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              options={[{label: 'All Roles', value: 'All'}, ...roles.map(r => ({ label: r.name, value: r.name }))]}
              placeholder={null}
            />
          </div>
          <div style={{ display: 'flex', gap: 'var(--spacing-3)' }}>
            {activeForm === null ? (
              <>
                <Button variant="primary" onClick={() => { setActiveForm('user'); setIsEditingUser(false); }}>+ Add User</Button>
                <Button variant="secondary" onClick={() => { setActiveForm('role'); setIsEditingUser(false); }}>+ Add Role</Button>
              </>
            ) : (
              <Button variant="secondary" onClick={resetUserForm}>Back to List</Button>
            )}
          </div>
        </div>
      }
    >
      <div className="animate-fade-in">
        <div className="users-roles-grid" style={{ marginBottom: activeForm ? 'var(--spacing-8)' : 0 }}>
          <AnimatePresence mode="wait">
            {/* User Form */}
            {activeForm === 'user' && (
              <motion.div
                key="user-form"
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: 'auto', opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                transition={{ duration: 0.3, ease: 'easeInOut' }}
                style={{ overflow: 'hidden' }}
              >
                <div className="user-management-section">
            <FormWrapper 
              title={isEditingUser ? "Edit User" : "Add New User"}
              onSubmit={handleUserSubmit}
              onCancel={isEditingUser ? resetUserForm : null}
              submitLabel={isEditingUser ? "Update User" : "Create User"}
            >
              <div className="user-form-grid">
                <div className={`image-preview-circle ${userErrors.photo ? 'has-error' : ''}`} style={{ alignSelf: 'center' }}>
                  {userFormData.photo ? <img src={userFormData.photo} alt="Preview" /> : null}
                </div>
                <div className="upload-field-container">
                  <Input 
                    label="User Photo" 
                    type="file" 
                    accept="image/*" 
                    onChange={handleUserPhotoChange} 
                    error={userErrors.photo} 
                    className="mb-0"
                  />
                  <p className="upload-hint">Max 2MB</p>
                </div>
                <Input label="Full Name" name="name" value={userFormData.name} onChange={handleUserInputChange} error={userErrors.name} required />
                
                <Input label="Email Address" name="email" value={userFormData.email} onChange={handleUserInputChange} error={userErrors.email} required />
                <Input label="Mobile Number" name="mobile" value={userFormData.mobile} onChange={handleUserInputChange} error={userErrors.mobile} required />
                <Select 
                  label="Role" 
                  name="role" 
                  value={userFormData.role} 
                  onChange={handleUserInputChange} 
                  options={roles.map(r => ({ label: r.name, value: r.name }))}
                  error={userErrors.role}
                  required 
                />
                <Select 
                  label="Status" 
                  name="status" 
                  value={userFormData.status} 
                  onChange={handleUserInputChange} 
                  options={[{label: 'Active', value: 'active'}, {label: 'Inactive', value: 'inactive'}]} 
                />
              </div>
            </FormWrapper>
          </div>
              </motion.div>
            )}

            {/* Role Form */}
            {activeForm === 'role' && (
              <motion.div
                key="role-form"
                initial={{ height: 0, opacity: 0 }}
                animate={{ height: 'auto', opacity: 1 }}
                exit={{ height: 0, opacity: 0 }}
                transition={{ duration: 0.3, ease: 'easeInOut' }}
                style={{ overflow: 'hidden' }}
              >
                <div className="role-management-section">
            <div className="card">
              <h3 className="card-title mb-6">Create New Role</h3>
              <Input label="Role Name" value={roleFormData.name} onChange={handleRoleInputChange} placeholder="e.g. Supervisor" />
              
              <div className="permissions-group">
                <p className="permissions-label">Assign Permissions</p>
                <div className="permissions-grid">
                  {permissionGroups.map(group => (
                    <label key={group.id} className="permission-item">
                      <input 
                        type="checkbox" 
                        checked={roleFormData.permissions.includes(group.id)}
                        onChange={() => handlePermissionToggle(group.id)}
                      />
                      <span>{group.label}</span>
                    </label>
                  ))}
                </div>
              </div>
              
              <div style={{ display: 'flex', gap: 'var(--spacing-3)', marginTop: 'var(--spacing-6)' }}>
                <Button variant="secondary" onClick={() => setActiveForm(null)} style={{flex: 1}}>
                  Cancel
                </Button>
                <Button variant="primary" onClick={handleRoleSubmit} style={{flex: 1}}>
                  Add Role
                </Button>
              </div>
            </div>
          </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Users Table */}
        <div className="card mt-8">
          <div className="table-controls">
            <h3 className="card-title">All Registered Users</h3>
          </div>
          <Table columns={columns} data={filteredUsers} />
        </div>
      </div>
    </PageContainer>
  );
};

export default Users;
