import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from './useAuth';
import { businessService } from '../services/business.service';
import { userService } from '../services/user.service';
import { roleService } from '../services/role.service';
import { generateId } from '../utils/idGenerator';
import Toast from '../components/common/Toast';
import { AnimatePresence } from 'framer-motion';

const DataContext = createContext();

export const DataProvider = ({ children }) => {
  const { user, switchBusiness } = useAuth();
  const businessId = user?.businessId;

  // State for all entity types
  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [inventoryLog, setInventoryLog] = useState([]);
  const [settings, setSettings] = useState({});
  const [users, setUsers] = useState([]);
  const [roles, setRoles] = useState([]);
  const [uoms, setUoms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);

  const showToast = (message, type = 'success') => {
    setToast({ message, type, id: Date.now() });
  };

  // Load data on user/business change
  useEffect(() => {
    const fetchBusinessData = async () => {
      if (businessId) {
        try {
          // Fetch all business context data
          const [businessesResult, usersResult, rolesResult] = await Promise.all([
            businessService.getMyBusinesses(),
            userService.getUsers(businessId),
            roleService.getRoles(businessId)
          ]);
          
          const rolesData = (rolesResult || []).map(role => {
            const permsObj = {};
            if (role.permissions && Array.isArray(role.permissions)) {
              role.permissions.forEach(p => {
                permsObj[p.module_name] = {
                  add: p.can_add,
                  view: p.can_view,
                  update: p.can_update,
                  delete: p.can_delete,
                  export: p.can_export,
                  import: p.can_bulk_upload,
                  download: p.can_download,
                  print: p.can_print
                };
              });
            }
            return { ...role, permissions: permsObj };
          });
          
          setUsers(usersResult || []);
          setRoles(rolesData);
          
          // Since other endpoints are missing, we initialize with empty or mock for now
          setCategories([]);
          setProducts([]);
          setTransactions([]);
          setInventoryLog([]);
          setSettings({});
          
          const defaultUoms = [
            { id: 'UOM-1', name: 'Pieces', shortCode: 'Pcs' },
            { id: 'UOM-2', name: 'Kilograms', shortCode: 'Kg' },
            { id: 'UOM-3', name: 'Liters', shortCode: 'Ltr' }
          ];
          setUoms(defaultUoms);
          
        } catch (error) {
          console.error('Error fetching business data:', error);
          showToast('Failed to load business data', 'error');
        }
      }
      setLoading(false);
    };

    fetchBusinessData();
  }, [businessId]);

  // CATEGORIES
  const addCategory = (category) => {
    const newCategory = { ...category, id: generateId('CAT-'), status: 'active' };
    setCategories(prev => {
      const updated = [...prev, newCategory];
      showToast('Category added successfully');
      return updated;
    });
  };

  const updateCategory = (id, updatedData) => {
    setCategories(prev => {
      const updated = prev.map(c => c.id === id ? { ...c, ...updatedData } : c);
      showToast('Category updated successfully');
      return updated;
    });
  };

  const deleteCategory = (id) => {
    setCategories(prev => {
      const categoryToDelete = prev.find(c => c.id === id);
      const updated = prev.filter(c => c.id !== id);
      
      // Cascade delete products
      if (categoryToDelete) {
        setProducts(prevProducts => {
          const updatedProducts = prevProducts.filter(p => p.category !== categoryToDelete.name);
          return updatedProducts;
        });
      }
      
      showToast('Category and related products deleted');
      return updated;
    });
  };

  // PRODUCTS
  const addProduct = (product) => {
    const newProduct = { ...product, id: generateId('PRD-'), status: 'active' };
    setProducts(prev => {
      const updated = [...prev, newProduct];
      showToast('Product added successfully');
      return updated;
    });
  };

  const updateProduct = (id, updatedData) => {
    setProducts(prev => {
      const updated = prev.map(p => p.id === id ? { ...p, ...updatedData } : p);
      showToast('Product updated successfully');
      return updated;
    });
  };

  const deleteProduct = (id) => {
    setProducts(prev => {
      const updated = prev.filter(p => p.id !== id);
      showToast('Product deleted successfully');
      return updated;
    });
  };

  // INVENTORY LOG & STOCK SYNC
  const addInventoryEntry = (entry) => {
    // 1. Find current stock to calculate stockAfter
    const product = products.find(p => p.id === entry.productId);
    const variant = product?.variants.find(v => v.name === entry.variantName);
    const currentStock = parseInt(variant?.stock) || 0;
    const finalStockAfter = Math.max(0, currentStock + entry.quantityChange);

    // 2. Update Products state and STORAGE
    setProducts(prevProducts => {
      const updatedProducts = prevProducts.map(p => {
        if (p.id === entry.productId) {
          const updatedVariants = p.variants.map(v => {
            if (v.name === entry.variantName) {
              return { ...v, stock: finalStockAfter };
            }
            return v;
          });
          return { ...p, variants: updatedVariants };
        }
        return p;
      });
      return updatedProducts;
    });

    // 3. Add to Inventory Log and STORAGE
    const logEntryWithStock = { 
      ...entry, 
      id: generateId('LOG-'), 
      date: new Date().toISOString(),
      doneBy: user?.name || 'Admin',
      stockAfter: finalStockAfter
    };
    
    setInventoryLog(prev => {
      const updated = [logEntryWithStock, ...prev];
      return updated;
    });

    // Show toast only for manual inventory updates, not for POS sales
    if (entry.reason !== 'Sale') {
      showToast(`${entry.type === 'IN' ? 'Added' : 'Reduced'} stock for ${entry.productName}`);
    }
  };

  // TRANSACTIONS
  const addTransaction = (transaction) => {
    const newTransaction = { 
      ...transaction, 
      id: generateId('INV-'), 
      date: new Date().toISOString(),
      status: 'Paid'
    };
    setTransactions(prev => {
      const updated = [newTransaction, ...prev];
      showToast('Transaction completed', 'success');
      return updated;
    });

    // Side effect: reduce stock for each item
    transaction.items.forEach(item => {
      addInventoryEntry({
        productId: item.productId,
        productName: item.name,
        variantName: item.variantName,
        type: 'OUT',
        quantityChange: -Math.abs(item.quantity),
        reason: 'Sale',
        stockAfter: 0 // Placeholder, handled in updateProductStock logic
      });
    });
  };

  // SETTINGS
  const updateSettings = (newSettings) => {
    setSettings(newSettings);
    showToast('Settings saved');
  };

  // USERS
  const addUser = async (userData) => {
    try {
      const payload = { ...userData, business_id: businessId };
      // Map role name to role_id
      const roleObj = roles.find(r => r.name === userData.role);
      if (roleObj) payload.role_id = roleObj.id;

      const result = await userService.createUser(payload);
      const newUser = { ...userData, id: result.user?.id || generateId('USR-') };
      setUsers(prev => [...prev, newUser]);
      showToast('User created successfully');
    } catch (error) {
      console.error('Add user error:', error);
      showToast(error.message || 'Failed to create user', 'error');
    }
  };

  const updateUser = async (id, updates) => {
    try {
      const payload = { ...updates, business_id: businessId };
      // Map role name to role_id if updated
      if (updates.role) {
        const roleObj = roles.find(r => r.name === updates.role);
        if (roleObj) payload.role_id = roleObj.id;
      }

      await userService.updateUser(id, payload);
      setUsers(prev => prev.map(u => u.id === id ? { ...u, ...updates } : u));
      showToast('User updated successfully');
    } catch (error) {
      console.error('Update user error:', error);
      showToast(error.message || 'Failed to update user', 'error');
    }
  };

  const deleteUser = async (id) => {
    try {
      await userService.deleteUser(id, businessId);
      setUsers(prev => prev.filter(u => u.id !== id));
      showToast('User deleted successfully');
    } catch (error) {
      console.error('Delete user error:', error);
      showToast(error.message || 'Failed to delete user', 'error');
    }
  };

  // ROLES
  const addRole = async (roleData) => {
    try {
      const payload = { ...roleData, business_id: businessId };
      const result = await roleService.createRole(payload);
      const newRole = { ...roleData, id: result.role?.id || generateId('ROL-') };
      setRoles(prev => [...prev, newRole]);
      showToast('Role created successfully');
    } catch (error) {
      console.error('Add role error:', error);
      showToast(error.message || 'Failed to create role', 'error');
    }
  };

  const updateRole = async (id, updates) => {
    try {
      await roleService.updateRole(id, updates);
      setRoles(prev => prev.map(r => r.id === id ? { ...r, ...updates } : r));
      showToast('Role updated successfully');
    } catch (error) {
      console.error('Update role error:', error);
      showToast(error.message || 'Failed to update role', 'error');
    }
  };

  // UOMs
  const addUom = (uom) => {
    const newUom = { ...uom, id: generateId('UOM-') };
    setUoms(prev => {
      const updated = [...prev, newUom];
      showToast('Unit added successfully');
      return updated;
    });
  };

  const updateUom = (id, updates) => {
    setUoms(prev => {
      const updated = prev.map(u => u.id === id ? { ...u, ...updates } : u);
      showToast('Unit updated successfully');
      return updated;
    });
  };

  const deleteUom = (id) => {
    setUoms(prev => {
      const updated = prev.filter(u => u.id !== id);
      showToast('Unit deleted successfully');
      return updated;
    });
  };

  // BUSINESSES
  const addBusiness = (businessData) => {
    showToast('Feature temporarily disabled pending API integration', 'error');
  };

  const deleteBusinessStore = (id) => {
    showToast('Feature temporarily disabled pending API integration', 'error');
  };

  const value = {
    businesses: [], // To be populated from API
    categories,
    products,
    transactions,
    inventoryLog,
    settings,
    users,
    roles,
    loading,
    addCategory,
    updateCategory,
    deleteCategory,
    addProduct,
    updateProduct,
    deleteProduct,
    addInventoryEntry,
    addTransaction,
    updateSettings,
    addUser,
    updateUser,
    deleteUser,
    addRole,
    updateRole,
    addBusiness,
    deleteBusiness: deleteBusinessStore,
    uoms,
    addUom,
    updateUom,
    deleteUom,
    showToast
  };

  return (
    <DataContext.Provider value={value}>
      {children}
      <AnimatePresence>
        {toast && (
          <Toast 
            key={toast.id}
            message={toast.message} 
            type={toast.type} 
            onClose={() => setToast(null)} 
          />
        )}
      </AnimatePresence>
    </DataContext.Provider>
  );
};

export const useDataContext = () => {
  const context = useContext(DataContext);
  if (!context) {
    throw new Error('useDataContext must be used within a DataProvider');
  }
  return context;
};
