import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from './useAuth';
import { getBusinessData, updateBusinessData } from '../utils/storage';
import { generateId } from '../utils/idGenerator';
import Toast from '../components/common/Toast';
import { AnimatePresence } from 'framer-motion';

const DataContext = createContext();

export const DataProvider = ({ children }) => {
  const { user } = useAuth();
  const businessId = user?.businessId;

  // State for all entity types
  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [inventoryLog, setInventoryLog] = useState([]);
  const [settings, setSettings] = useState({});
  const [users, setUsers] = useState([]);
  const [roles, setRoles] = useState([]);
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
      return updated;
    });
  };

  const updateProductStock = (productId, variantName, quantityChange) => {
    setProducts(prev => {
      const updated = prev.map(p => {
        if (p.id === productId) {
          const updatedVariants = p.variants.map(v => 
            v.name === variantName 
              ? { ...v, stock: Math.max(0, (parseInt(v.stock) || 0) + quantityChange) } 
              : v
          );
          return { ...p, variants: updatedVariants };
        }
        return p;
      });
      updateBusinessData(businessId, 'products', updated);
      return updated;
    });
  };

  // INVENTORY LOG
  const addInventoryEntry = (entry) => {
    const newEntry = { 
      ...entry, 
      id: generateId('LOG-'), 
      date: new Date().toISOString(),
      doneBy: user?.name || 'Admin'
    };
    setInventoryLog(prev => {
      const updated = [newEntry, ...prev];
      updateBusinessData(businessId, 'inventory_log', updated);
      return updated;
    });

    // Side effect: update product stock
    updateProductStock(entry.productId, entry.variantName, entry.quantityChange);
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
    showToast('Settings saved');
  };

  // USERS
  const addUser = (user) => {
    const newUser = { ...user, id: generateId('USR-') };
    setUsers(prev => {
      const updated = [...prev, newUser];
      updateBusinessData(businessId, 'business_users', updated);
      return updated;
    });
  };

  const updateUser = (id, updates) => {
    setUsers(prev => {
      const updated = prev.map(u => u.id === id ? { ...u, ...updates } : u);
      updateBusinessData(businessId, 'business_users', updated);
      return updated;
    });
  };

  const deleteUser = (id) => {
    setUsers(prev => {
      const updated = prev.map(u => u.id === id ? { ...u, status: 'inactive' } : u);
      updateBusinessData(businessId, 'business_users', updated);
      return updated;
    });
  };

  // ROLES
  const addRole = (role) => {
    const newRole = { ...role, id: generateId('ROL-') };
    setRoles(prev => {
      const updated = [...prev, newRole];
      updateBusinessData(businessId, 'roles', updated);
      return updated;
    });
  };

  const value = {
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
    addProduct,
    updateProduct,
    addInventoryEntry,
    addTransaction,
    updateSettings,
    addUser,
    updateUser,
    deleteUser,
    addRole
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
