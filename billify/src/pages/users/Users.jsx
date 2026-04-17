import React, { useState, useMemo, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import FormWrapper from '../../components/common/FormWrapper';
import Input from '../../components/common/Input';
import Select from '../../components/common/Select';
import Button from '../../components/common/Button';
import Table from '../../components/common/Table';
import ToggleSwitch from '../../components/common/ToggleSwitch';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import { fileToBase64, validateImage } from '../../utils/fileHelpers';
import { exportToCSV, importFromCSV, downloadTemplate as downloadCSVTemplate } from '../../utils/csvService';

const Users = () => {
  const fileInputRef = useRef(null);
  const { users, roles, addUser, updateUser, deleteUser, addRole, updateRole, showToast } = useDataContext();

  // Tab State
  const [activeTab, setActiveTab] = useState('users'); // 'users' | 'roles'
  
  // Permissions Configuration
  const MODULES = [
    { id: 'dashboard', label: 'Dashboard', group: 'Reports' },
    { id: 'products', label: 'Products Master', group: 'Masters' },
    { id: 'categories', label: 'Categories Master', group: 'Masters' },
    { id: 'users', label: 'User Management', group: 'Masters' },
    { id: 'billing', label: 'Billing / POS', group: 'Transactions' },
    { id: 'transactions', label: 'Transaction Logs', group: 'Transactions' },
    { id: 'inventory', label: 'Inventory Management', group: 'Transactions' },
    { id: 'uoms', label: 'Units of Measurement', group: 'Settings' },
    { id: 'reports', label: 'Analytics & Reports', group: 'Reports' },
    { id: 'settings', label: 'System Settings', group: 'Settings' },
  ];

  const ACTIONS = [
    { id: 'add', label: 'Add' },
    { id: 'view', label: 'View' },
    { id: 'update', label: 'Update' },
    { id: 'delete', label: 'Delete' },
    { id: 'export', label: 'Export' },
    { id: 'import', label: 'Bulk Upload' },
    { id: 'download', label: 'Download' },
    { id: 'print', label: 'Print' },
  ];

  // State
  const [activeForm, setActiveForm] = useState(null); // null | 'user' | 'role'
  
  const [isEditingUser, setIsEditingUser] = useState(false);
  const [editingUserId, setEditingUserId] = useState(null);
  
  const [isEditingRole, setIsEditingRole] = useState(false);
  const [editingRoleId, setEditingRoleId] = useState(null);

  const [userFormData, setUserFormData] = useState({
    name: '',
    email: '',
    mobile: '',
    role: '',
    password: '',
    status: 'active',
    photo: ''
  });
  const [userErrors, setUserErrors] = useState({});
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [userToDelete, setUserToDelete] = useState(null);

  const [roleFormData, setRoleFormData] = useState({
    name: '',
    permissions: {} // { [moduleId]: { [actionId]: boolean } }
  });

  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('All');

  // User Handlers
  const handleUserInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    const val = type === 'checkbox' ? (checked ? 'active' : 'inactive') : value;
    setUserFormData(prev => ({ ...prev, [name]: val }));
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
    if (!userFormData.name?.trim()) errors.name = 'Name is required';
    if (!userFormData.email?.trim() || !/\S+@\S+\.\S+/.test(userFormData.email)) errors.email = 'Valid email required';
    if (!userFormData.mobile?.trim() || !/^\d{10}$/.test(userFormData.mobile)) errors.mobile = '10-digit mobile required';
    if (!userFormData.role) errors.role = 'Role required';
    if (!isEditingUser && !userFormData.password?.trim()) errors.password = 'Password is required';
    setUserErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleUserSubmit = async () => {
    if (!validateUserForm()) return;

    try {
      if (isEditingUser) {
        await updateUser(editingUserId, userFormData);
        setIsEditingUser(false);
        setEditingUserId(null);
      } else {
        await addUser({ ...userFormData, status: 'active' });
      }
      resetUserForm();
    } catch (err) {
      // Error is already handled by showToast in context, but we can log it here
      console.error('Submit user error:', err);
    }
  };

  const resetUserForm = () => {
    setUserFormData({ name: '', email: '', mobile: '', role: '', password: '', status: 'active', photo: '' });
    setUserErrors({});
    setIsEditingUser(false);
    setActiveForm(null);
  };

  const handleEditUser = (user) => {
    setIsEditingUser(true);
    setEditingUserId(user.id);
    setUserFormData({ 
      ...user,
      mobile: user.mobile || '',
      photo: user.photo || '',
      password: '' // Reset password on edit
    });
    setActiveForm('user');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleDeleteUser = (id) => {
    setUserToDelete(id);
    setIsConfirmOpen(true);
  };

  // Bulk Handlers (CSV)
  const handleDownloadTemplate = () => {
    downloadCSVTemplate(['name', 'email', 'mobile', 'role'], 'users_template');
  };

  const handleExportUsers = () => {
    const exportData = users.map(u => ({
      name: u.name,
      email: u.email,
      mobile: u.mobile,
      role: u.role,
      status: u.status
    }));
    exportToCSV(exportData, 'self_billing_users');
  };

  const handleImportCSV = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    try {
      const data = await importFromCSV(file);
      data.forEach(item => {
        if (item.name && item.email) {
          addUser({
            name: item.name,
            email: item.email,
            mobile: item.mobile || '',
            role: item.role || 'Cashier',
            status: 'active'
          });
        }
      });
      showToast(`Imported ${data.length} users!`, 'success');
      e.target.value = '';
    } catch (err) {
      showToast('Error importing users: ' + err.message, 'error');
    }
  };

  // Role Handlers (Permissions Grid)
  const handleRoleInputChange = (e) => {
    setRoleFormData(prev => ({ ...prev, name: e.target.value }));
  };

  const togglePermission = (moduleId, actionId) => {
    setRoleFormData(prev => {
      const modulePerms = prev.permissions[moduleId] || {};
      return {
        ...prev,
        permissions: {
          ...prev.permissions,
          [moduleId]: {
            ...modulePerms,
            [actionId]: !modulePerms[actionId]
          }
        }
      };
    });
  };

  const toggleAllForModule = (moduleId, checked) => {
    setRoleFormData(prev => {
      const newModulePerms = {};
      ACTIONS.forEach(action => {
        newModulePerms[action.id] = checked;
      });
      return {
        ...prev,
        permissions: {
          ...prev.permissions,
          [moduleId]: newModulePerms
        }
      };
    });
  };

  const toggleAllForAction = (actionId, checked) => {
    setRoleFormData(prev => {
      const newPermissions = { ...prev.permissions };
      MODULES.forEach(module => {
        newPermissions[module.id] = {
          ...(newPermissions[module.id] || {}),
          [actionId]: checked
        };
      });
      return { ...prev, permissions: newPermissions };
    });
  };

  const toggleAllForGroup = (groupName, checked) => {
    setRoleFormData(prev => {
      const newPermissions = { ...prev.permissions };
      const groupModules = MODULES.filter(m => m.group === groupName);
      groupModules.forEach(module => {
        newPermissions[module.id] = {};
        ACTIONS.forEach(action => {
          newPermissions[module.id][action.id] = checked;
        });
      });
      return { ...prev, permissions: newPermissions };
    });
  };

  const toggleAllPermissions = (checked) => {
    setRoleFormData(prev => {
      const newPermissions = {};
      MODULES.forEach(module => {
        newPermissions[module.id] = {};
        ACTIONS.forEach(action => {
          newPermissions[module.id][action.id] = checked;
        });
      });
      return { ...prev, permissions: newPermissions };
    });
  };

  const handleRoleSubmit = async () => {
    if (!roleFormData.name.trim()) {
      showToast('Role name is required', 'warning');
      return;
    }
    
    try {
      if (isEditingRole) {
        await updateRole(editingRoleId, roleFormData);
      } else {
        await addRole(roleFormData);
      }
      resetRoleForm();
    } catch (err) {
      console.error('Submit role error:', err);
    }
  };

  const resetRoleForm = () => {
    setRoleFormData({ name: '', permissions: {} });
    setIsEditingRole(false);
    setEditingRoleId(null);
    // Keep activeForm as 'role' if we are on the roles tab
    if (activeTab === 'roles') {
      setActiveForm('role');
    } else {
      setActiveForm(null);
    }
  };

  const handleEditRole = (role) => {
    setIsEditingRole(true);
    setEditingRoleId(role.id);
    setRoleFormData({ 
      name: role.name, 
      permissions: role.permissions || {} 
    });
    setActiveTab('roles');
    setActiveForm('role');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const isModuleFullySelected = (moduleId) => {
    return ACTIONS.every(action => roleFormData.permissions[moduleId]?.[action.id]);
  };

  const isActionFullySelected = (actionId) => {
    return MODULES.every(module => roleFormData.permissions[module.id]?.[actionId]);
  };

  const isAllFullySelected = () => {
    return MODULES.every(module => ACTIONS.every(action => roleFormData.permissions[module.id]?.[action.id]));
  };

  const isGroupFullySelected = (groupName) => {
    const groupModules = MODULES.filter(m => m.group === groupName);
    return groupModules.every(module => ACTIONS.every(action => roleFormData.permissions[module.id]?.[action.id]));
  };

  const isActionFullySelectedForGroup = (groupName, actionId) => {
    const groupModules = MODULES.filter(m => m.group === groupName);
    return groupModules.every(module => roleFormData.permissions[module.id]?.[actionId]);
  };

  // Group modules for rendering
  const moduleGroups = MODULES.reduce((acc, module) => {
    if (!acc[module.group]) acc[module.group] = [];
    acc[module.group].push(module);
    return acc;
  }, {});

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
      render: (val) => {
        const text = typeof val === 'string' ? val : (val ? 'active' : 'inactive');
        return (
          <span className={`status-badge ${text}`}>
            {text.charAt(0).toUpperCase() + text.slice(1)}
          </span>
        );
      }
    },
    {
      key: 'actions',
      label: 'Actions',
      render: (_, row) => (
        <div style={{display: 'flex', gap: 'var(--spacing-2)'}}>
          <button 
            className="btn-icon-primary" 
            onClick={() => handleEditUser(row)} 
            title="Edit User"
          >
            ✏️
          </button>
          <button 
            className="btn-icon-danger" 
            onClick={() => handleDeleteUser(row.id)} 
            title="Delete User"
          >
            🗑️
          </button>
        </div>
      )
    }
  ];
  const renderPermissionsMatrix = () => (
    <div className="table-responsive">
      <table className="permissions-table">
        <thead>
          <tr>
            <th>Module</th>
            {ACTIONS.map(action => (
              <th key={action.id} className="text-center">{action.label}</th>
            ))}
            <th className="text-center">All</th>
          </tr>
        </thead>
        <tbody>
          <tr className="all-permissions-row">
            <td className="font-bold">All Permissions</td>
            {ACTIONS.map(action => (
              <td key={action.id} className="text-center">
                <input 
                  type="checkbox" 
                  checked={isActionFullySelected(action.id)}
                  onChange={(e) => toggleAllForAction(action.id, e.target.checked)}
                />
              </td>
            ))}
            <td className="text-center">
              <input 
                type="checkbox" 
                checked={isAllFullySelected()}
                onChange={(e) => toggleAllPermissions(e.target.checked)}
              />
            </td>
          </tr>
          {Object.entries(moduleGroups).map(([groupName, modules]) => (
            <React.Fragment key={groupName}>
              <tr className="module-group-row">
                <td className="font-bold">{groupName}</td>
                {ACTIONS.map(action => (
                  <td key={action.id} className="text-center">
                    <input 
                      type="checkbox" 
                      checked={isActionFullySelectedForGroup(groupName, action.id)}
                      onChange={(e) => {
                        const newPermissions = { ...roleFormData.permissions };
                        modules.forEach(m => {
                          newPermissions[m.id] = {
                            ...(newPermissions[m.id] || {}),
                            [action.id]: e.target.checked
                          };
                        });
                        setRoleFormData(prev => ({ ...prev, permissions: newPermissions }));
                      }}
                    />
                  </td>
                ))}
                <td className="text-center">
                  <input 
                    type="checkbox" 
                    checked={isGroupFullySelected(groupName)}
                    onChange={(e) => toggleAllForGroup(groupName, e.target.checked)}
                  />
                </td>
              </tr>
              {modules.map(module => (
                <tr key={module.id} className="module-row">
                  <td className="module-label">— {module.label}</td>
                  {ACTIONS.map(action => (
                    <td key={action.id} className="text-center">
                      <input 
                        type="checkbox"
                        checked={!!roleFormData.permissions[module.id]?.[action.id]}
                        onChange={() => togglePermission(module.id, action.id)}
                      />
                    </td>
                  ))}
                  <td className="text-center">
                    <input 
                      type="checkbox"
                      checked={isModuleFullySelected(module.id)}
                      onChange={(e) => toggleAllForModule(module.id, e.target.checked)}
                    />
                  </td>
                </tr>
              ))}
            </React.Fragment>
          ))}
        </tbody>
      </table>
    </div>
  );

  return (
    <PageContainer 
      title="Users & Roles Management"
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-4)', alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          {activeTab === 'users' && !activeForm && (
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
          )}
          
          <div style={{ display: 'flex', gap: 'var(--spacing-3)' }}>
            {activeForm === null ? (
              <>
                {activeTab === 'users' ? (
                  <>
                    <Button variant="primary" onClick={() => { setActiveForm('user'); setIsEditingUser(false); }}>+ Add User</Button>
                    <Button variant="secondary" onClick={handleDownloadTemplate}>Template</Button>
                    <Button variant="secondary" onClick={() => fileInputRef.current.click()}>Import</Button>
                    <Button variant="secondary" onClick={handleExportUsers}>Export</Button>
                  </>
                ) : (
                  <Button variant="primary" onClick={() => { resetRoleForm(); setActiveForm('role'); setIsEditingRole(false); }}>+ Add Role</Button>
                )}
                <input 
                  type="file" 
                  ref={fileInputRef} 
                  style={{ display: 'none' }} 
                  accept=".csv" 
                  onChange={handleImportCSV} 
                />
              </>
            ) : (
              <>
                {activeTab === 'users' && (
                  <Button variant="secondary" onClick={resetUserForm}>Back to List</Button>
                )}
              </>
            )}
          </div>
        </div>
      }
    >
      <div className="animate-fade-in">
        {/* Tab Navigation */}
        <div className="tabs-container">
          <button 
            className={`tab-btn ${activeTab === 'users' ? 'active' : ''}`}
            onClick={() => { setActiveTab('users'); setActiveForm(null); }}
          >
            Users List
          </button>
          <button 
            className={`tab-btn ${activeTab === 'roles' ? 'active' : ''}`}
            onClick={() => { setActiveTab('roles'); setActiveForm(null); resetRoleForm(); }}
          >
            Roles & Permissions
          </button>
        </div>

        <div className="users-roles-grid" style={{ marginBottom: activeForm ? 'var(--spacing-8)' : 0 }}>
          <AnimatePresence mode="wait">
            {/* User Form */}
            {activeTab === 'users' && activeForm === 'user' && (
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
                      <Input 
                        label="Password" 
                        name="password" 
                        type="password"
                        value={userFormData.password} 
                        onChange={handleUserInputChange} 
                        error={userErrors.password} 
                        required={!isEditingUser}
                        placeholder={isEditingUser ? "Leave blank to keep current" : "Enter password"}
                      />
                      <ToggleSwitch 
                        label="Account Status" 
                        name="status" 
                        checked={userFormData.status === 'active'} 
                        onChange={handleUserInputChange} 
                      />
                    </div>
                  </FormWrapper>
                </div>
              </motion.div>
            )}

            {/* Role Form */}
            {/* Role Form (Create & Edit) */}
            {activeTab === 'roles' && (
              <motion.div
                key="role-form-container"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.3 }}
              >
                <div className="role-management-section">
                  {/* Create New Role (Visible when activeForm is 'role') */}
                  {activeForm === 'role' && !isEditingRole && (
                    <div className="card mb-8">
                      <h3 className="card-title mb-6">Create New Role</h3>
                      <div className="product-form-grid mb-6">
                        <Input 
                          label="Role Name" 
                          value={roleFormData.name} 
                          onChange={handleRoleInputChange} 
                          placeholder="e.g. Supervisor" 
                        />
                      </div>
                      
                      <div className="permissions-matrix-container">
                        <h4 className="section-title-small mb-4">Assign Permissions Matrix</h4>
                        {/* Matrix Component Call */}
                        {renderPermissionsMatrix()}
                      </div>

                      <div style={{ display: 'flex', gap: 'var(--spacing-3)', marginTop: 'var(--spacing-8)' }}>
                        <Button variant="secondary" onClick={() => setActiveForm(null)} style={{flex: 1}}>
                          Cancel
                        </Button>
                        <Button variant="primary" onClick={handleRoleSubmit} style={{flex: 1}}>
                          Add Role
                        </Button>
                      </div>
                    </div>
                  )}

                  {/* Move Editing Role (Dropdown + Matrix) */}
                  <div className="card">
                    <div className="role-selector-primary mb-8">
                      <p className="field-label mb-2">Select Role to Manage</p>
                      <Select
                        placeholder="Choose an existing role..."
                        value={isEditingRole ? editingRoleId : ''}
                        onChange={(e) => {
                          const role = roles.find(r => String(r.id) === String(e.target.value));
                          if (role) handleEditRole(role);
                          else {
                            resetRoleForm();
                            setIsEditingRole(false);
                          }
                        }}
                        options={roles.map(r => ({ label: r.name, value: r.id }))}
                        className="role-prominent-select"
                      />
                    </div>
                    
                    {isEditingRole && (
                      <div className="animate-fade-in">
                        <h3 className="card-title mb-6">Editing: {roleFormData.name}</h3>
                        <div className="permissions-matrix-container">
                          {renderPermissionsMatrix()}
                        </div>

                        <div style={{ display: 'flex', gap: 'var(--spacing-3)', marginTop: 'var(--spacing-8)' }}>
                          <Button variant="secondary" onClick={() => { resetRoleForm(); setActiveForm(null); }} style={{flex: 1}}>
                            Cancel
                          </Button>
                          <Button variant="primary" onClick={handleRoleSubmit} style={{flex: 1}}>
                            Update Permissions
                          </Button>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Dynamic Table Section (Users Only) */}
        {!activeForm && activeTab === 'users' && (
          <div className="card mt-8">
            <div className="table-controls">
              <h3 className="card-title">Registered Users</h3>
            </div>
            <Table columns={columns} data={filteredUsers} />
          </div>
        )}
      </div>
      <ConfirmDialog 
        isOpen={isConfirmOpen} 
        onClose={() => setIsConfirmOpen(false)} 
        onConfirm={() => deleteUser(userToDelete)} 
        title="Delete User"
        message="Are you sure you want to permanently delete this user? This action cannot be undone."
      />
    </PageContainer>
  );
};

export default Users;
