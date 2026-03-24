import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from './useAuth';
import { getBusinessData, updateBusinessData, getAllBusinesses, addNewBusiness, updateBusinessName, deleteBusiness, saveUser, deleteGlobalUser } from '../utils/storage';
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
    if (businessId) {
      setCategories(getBusinessData(businessId, 'categories'));
      setProducts(getBusinessData(businessId, 'products'));
      setTransactions(getBusinessData(businessId, 'transactions'));
      setInventoryLog(getBusinessData(businessId, 'inventory_log'));
      setSettings(getBusinessData(businessId, 'settings'));
      setUsers(getBusinessData(businessId, 'business_users'));
      setRoles(getBusinessData(businessId, 'roles'));
      
      const savedUoms = getBusinessData(businessId, 'uoms');
      if (savedUoms.length === 0) {
        const defaultUoms = [
          { id: 'UOM-1', name: 'Pieces', shortCode: 'Pcs' },
          { id: 'UOM-2', name: 'Kilograms', shortCode: 'Kg' },
          { id: 'UOM-3', name: 'Liters', shortCode: 'Ltr' }
        ];
        setUoms(defaultUoms);
        updateBusinessData(businessId, 'uoms', defaultUoms);
      } else {
        setUoms(savedUoms);
      }
    }
    setLoading(false);
  }, [businessId]);

  // CATEGORIES
  const addCategory = (category) => {
    const newCategory = { ...category, id: generateId('CAT-'), status: 'active' };
    setCategories(prev => {
      const updated = [...prev, newCategory];
      updateBusinessData(businessId, 'categories', updated);
      showToast('Category added successfully');
      return updated;
    });
  };

  const updateCategory = (id, updatedData) => {
    setCategories(prev => {
      const updated = prev.map(c => c.id === id ? { ...c, ...updatedData } : c);
      updateBusinessData(businessId, 'categories', updated);
      showToast('Category updated successfully');
      return updated;
    });
  };

  const deleteCategory = (id) => {
    setCategories(prev => {
      const categoryToDelete = prev.find(c => c.id === id);
      const updated = prev.filter(c => c.id !== id);
      updateBusinessData(businessId, 'categories', updated);
      
      // Cascade delete products
      if (categoryToDelete) {
        setProducts(prevProducts => {
          const updatedProducts = prevProducts.filter(p => p.category !== categoryToDelete.name);
          updateBusinessData(businessId, 'products', updatedProducts);
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
      updateBusinessData(businessId, 'products', updated);
      showToast('Product added successfully');
      return updated;
    });
  };

  const updateProduct = (id, updatedData) => {
    setProducts(prev => {
      const updated = prev.map(p => p.id === id ? { ...p, ...updatedData } : p);
      updateBusinessData(businessId, 'products', updated);
      showToast('Product updated successfully');
      return updated;
    });
  };

  const deleteProduct = (id) => {
    setProducts(prev => {
      const updated = prev.filter(p => p.id !== id);
      updateBusinessData(businessId, 'products', updated);
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
      updateBusinessData(businessId, 'products', updatedProducts);
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
      updateBusinessData(businessId, 'inventory_log', updated);
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
      updateBusinessData(businessId, 'transactions', updated);
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
    updateBusinessData(businessId, 'settings', newSettings);
    
    // Sync business name to global business list
    if (newSettings.businessName) {
      updateBusinessName(businessId, newSettings.businessName);
    }
    
    showToast('Settings saved');
  };

  // USERS
  const addUser = (userData) => {
    const newUser = { ...userData, id: generateId('USR-') };
    setUsers(prev => {
      const updated = [...prev, newUser];
      updateBusinessData(businessId, 'business_users', updated);
      
      // Sync with global auth registry
      saveUser({ ...newUser, businessId });
      
      return updated;
    });
  };

  const updateUser = (id, updates) => {
    setUsers(prev => {
      const updated = prev.map(u => u.id === id ? { ...u, ...updates } : u);
      updateBusinessData(businessId, 'business_users', updated);
      
      // Sync with global auth registry
      const updatedUser = updated.find(u => u.id === id);
      if (updatedUser) {
        saveUser({ ...updatedUser, businessId });
      }
      
      return updated;
    });
  };

  const deleteUser = (id) => {
    setUsers(prev => {
      const userToDelete = prev.find(u => u.id === id);
      const updated = prev.filter(u => u.id !== id);
      updateBusinessData(businessId, 'business_users', updated);
      
      // Remove from global auth registry
      if (userToDelete) {
        deleteGlobalUser(userToDelete.email);
      }
      
      showToast('User deleted successfully');
      return updated;
    });
  };

  // ROLES
  const addRole = (role) => {
    const newRole = { ...role, id: generateId('ROL-') };
    setRoles(prev => {
      const updated = [...prev, newRole];
      updateBusinessData(businessId, 'roles', updated);
      showToast('Role created successfully');
      return updated;
    });
  };

  const updateRole = (id, updates) => {
    setRoles(prev => {
      const updated = prev.map(r => r.id === id ? { ...r, ...updates } : r);
      updateBusinessData(businessId, 'roles', updated);
      showToast('Role updated successfully');
      return updated;
    });
  };

  // UOMs
  const addUom = (uom) => {
    const newUom = { ...uom, id: generateId('UOM-') };
    setUoms(prev => {
      const updated = [...prev, newUom];
      updateBusinessData(businessId, 'uoms', updated);
      showToast('Unit added successfully');
      return updated;
    });
  };

  const updateUom = (id, updates) => {
    setUoms(prev => {
      const updated = prev.map(u => u.id === id ? { ...u, ...updates } : u);
      updateBusinessData(businessId, 'uoms', updated);
      showToast('Unit updated successfully');
      return updated;
    });
  };

  const deleteUom = (id) => {
    setUoms(prev => {
      const updated = prev.filter(u => u.id !== id);
      updateBusinessData(businessId, 'uoms', updated);
      showToast('Unit deleted successfully');
      return updated;
    });
  };

  // BUSINESSES
  const addBusiness = (businessData) => {
    const newBiz = addNewBusiness(businessData);
    showToast('Business created successfully');
    return newBiz;
  };

  const deleteBusinessStore = (id) => {
    const remaining = getAllBusinesses().filter(b => b.id !== id);
    
    // Safety: Don't allow deleting the last business
    if (remaining.length === 0) {
      showToast('Cannot delete the last business. Add another first.', 'error');
      return;
    }

    deleteBusiness(id);
    showToast('Business and all data deleted');
    
    // If active business was deleted, switch to the first remaining one
    if (businessId === id && remaining.length > 0) {
      switchBusiness(remaining[0].id);
    }
  };

  const value = {
    businesses: getAllBusinesses(),
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
