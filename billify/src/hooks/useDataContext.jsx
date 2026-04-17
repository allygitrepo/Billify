import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from './useAuth';
import { businessService } from '../services/business.service';
import { userService } from '../services/user.service';
import { roleService } from '../services/role.service';
import { categoryService } from '../services/category.service';
import { productService } from '../services/product.service';
import { uomService } from '../services/uom.service';
import { invoiceService } from '../services/invoice.service';
import { inventoryService } from '../services/inventory.service';
import { settingsService } from '../services/settings.service';
import { qrService } from '../services/qr.service';
import { generateId } from '../utils/idGenerator';

import Toast from '../components/common/Toast';
import { AnimatePresence } from 'framer-motion';

const DataContext = createContext();

export const DataProvider = ({ children }) => {
  const { user, switchBusiness } = useAuth();
  const businessId = user?.businessId;

  // State for all entity types
  const [businesses, setBusinesses] = useState([]);
  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [inventoryLog, setInventoryLog] = useState([]);
  const [settings, setSettings] = useState({});
  const [users, setUsers] = useState([]);
  const [roles, setRoles] = useState([]);
  const [uoms, setUoms] = useState([]);
  const [qrCodes, setQrCodes] = useState([]);
  const [customers, setCustomers] = useState([]);
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
          const [
            businessesResult, 
            usersResult, 
            rolesResult, 
            categoriesResult, 
            productsResult, 
            uomsResult,
            transactionsResult,
            inventoryResult,
            settingsResult,
            qrCodesResult
          ] = await Promise.all([

            businessService.getMyBusinesses(),
            userService.getUsers(businessId),
            roleService.getRoles(businessId),
            categoryService.getCategories(businessId),
            productService.getProducts(businessId),
            uomService.getUOMs(businessId),
            invoiceService.getInvoices(businessId),
            inventoryService.getInventoryLog(businessId),
            settingsService.getSettings(businessId),
            qrService.getQRByBusiness(businessId)
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
          
          const productsData = (productsResult || []).map(p => ({
            ...p,
            category: p.category ? p.category.name : ''
          }));
          
          // Map settings to camelCase for UI
          const mappedSettings = settingsResult ? {
            businessName: settingsResult.business_name || '',
            gstNumber: settingsResult.gst_number || '',
            phone: settingsResult.business_phone || '',
            address: settingsResult.business_address || '',
            taxPercentage: settingsResult.tax_percentage || 0,
            gstPercentage: settingsResult.gst_percentage || 0,
            currency: settingsResult.currency || 'INR',
            invoicePrefix: settingsResult.invoice_prefix || 'INV',
            startingNumber: settingsResult.starting_invoice_number || 1001,
            footerNote: settingsResult.footer_note || '',
            invoiceFormat: settingsResult.invoice_format || 'thermal',
            photo: settingsResult.business_logo || '',
            categoryCompulsory: settingsResult.category_compulsory !== undefined ? settingsResult.category_compulsory : true,
            variantsEnabled: settingsResult.variants_enabled !== undefined ? settingsResult.variants_enabled : true
          } : {};

          const mappedLogs = (inventoryResult || []).map(log => ({
            id: log.id,
            productId: log.product_id,
            productName: log.product?.name || 'Unknown',
            variantName: log.variant_name,
            type: log.change_type,
            quantityChange: log.quantity_change,
            reason: log.reason,
            stockAfter: log.stock_after,
            doneBy: log.user?.name || 'Admin',
            referenceNo: log.reference_no,
            entityName: log.entity_name,
            unitPrice: log.unit_price,
            totalAmount: log.total_amount,
            date: log.createdAt
          }));

          const mappedTransactions = (transactionsResult || []).map(t => ({
            id: t.invoice_number || t.id.toString(),
            dbId: t.id,
            type: 'Invoice',
            date: t.createdAt,
            items: (t.items || []).map(item => {
              // Try to find current product name for legacy transactions
              const currentProd = productsResult.find(p => p.id === item.product_id);
              return {
                id: item.id,
                productId: item.product_id,
                name: item.product_name || currentProd?.name || 'Product',
                variantName: item.variant_name,
                quantity: item.quantity,
                price: parseFloat(item.price),
                subtotal: parseFloat(item.subtotal)
              };
            }),
            paymentMethod: t.payment_mode,
            subtotal: parseFloat(t.total_amount),
            tax: parseFloat(t.tax_amount),
            gst: 0, 
            discount: parseFloat(t.discount),
            total: parseFloat(t.final_amount || 0),
            paid: parseFloat(t.paid_amount || 0),
            pending: parseFloat(t.final_amount || 0) - parseFloat(t.paid_amount || 0),
            cashierName: t.user?.name || 'Admin',
            customerName: t.customer_name || 'Walking Customer',
            customerPhone: t.customer_phone || '',
            status: t.status
          }));

          setUsers(usersResult || []);
          setRoles(rolesData);
          setCategories(categoriesResult || []);
          setProducts(productsData);
          setUoms(uomsResult || []);
          setTransactions(mappedTransactions);
          setInventoryLog(mappedLogs);
          setSettings(mappedSettings);
          setBusinesses(businessesResult || []);
          setQrCodes(qrCodesResult || []);
          
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
  const addCategory = async (categoryData) => {
    try {
      const payload = { ...categoryData, business_id: businessId };
      const result = await categoryService.createCategory(payload);
      const newCategory = { ...categoryData, id: result.category?.id || generateId('CAT-') };
      setCategories(prev => [...prev, newCategory]);
      showToast('Category added successfully');
      return result;
    } catch (error) {
      console.error('Add category error:', error);
      if (error.status === 409) throw error;
      showToast(error.message || 'Failed to add category', 'error');
    }
  };

  const updateCategory = async (id, updatedData) => {
    try {
      await categoryService.updateCategory(id, updatedData);
      setCategories(prev => prev.map(c => c.id === id ? { ...c, ...updatedData } : c));
      showToast('Category updated successfully');
    } catch (error) {
      console.error('Update category error:', error);
      showToast(error.message || 'Failed to update category', 'error');
    }
  };

  const deleteCategory = async (id) => {
    try {
      await categoryService.deleteCategory(id);
      setCategories(prev => {
        const categoryToDelete = prev.find(c => c.id === id);
        const updated = prev.filter(c => c.id !== id);
        
        // Cascade locally (backend also handles it)
        if (categoryToDelete) {
          setProducts(prevProducts => prevProducts.filter(p => p.category !== categoryToDelete.name));
        }
        return updated;
      });
      showToast('Category and related products deleted');
    } catch (error) {
      console.error('Delete category error:', error);
      showToast(error.message || 'Failed to delete category', 'error');
    }
  };

  // PRODUCTS
  const addProduct = async (productData) => {
    try {
      let finalCategoryId = null;
      let categoriesToUpdate = [...categories];

      // 1. Check if category exists or needs to be created
      if (productData.category) {
        let catObj = categories.find(c => c.name === productData.category);
        
        if (!catObj) {
          // Create new category first to get ID and update state
          try {
            const catPayload = { business_id: businessId, name: productData.category, status: 'active' };
            const catResult = await categoryService.createCategory(catPayload);
            catObj = { ...catPayload, id: catResult.category?.id };
            
            // Update local categories state
            setCategories(prev => [...prev, catObj]);
            categoriesToUpdate = [...categories, catObj];
          } catch (error) {
            if (error.status === 409) {
              // If it already exists, just fetch it from the latest list (or API)
              const allCats = await categoryService.getCategories(businessId);
              setCategories(allCats);
              catObj = allCats.find(c => c.name === productData.category);
            } else {
              throw error;
            }
          }
        }
        finalCategoryId = catObj.id;
      }

      // 1.5. Check if UOM exists or needs to be created
      if (productData.uom) {
        const uomObj = uoms.find(u => u.shortCode === productData.uom || u.name === productData.uom);
        
        if (!uomObj) {
          try {
            const uomPayload = { 
              business_id: businessId, 
              name: productData.uom, 
              shortCode: productData.uom, 
              status: true 
            };
            const uomResult = await uomService.createUOM(uomPayload);
            const newUom = { ...uomPayload, id: uomResult.uom?.id };
            setUoms(prev => [...prev, newUom]);
          } catch (error) {
            if (error.status === 409) {
              const allUoms = await uomService.getUOMs(businessId);
              setUoms(allUoms);
            } else {
              // Non-critical error, just log it
              console.warn('UOM auto-creation failed:', error);
            }
          }
        }
      }

      // 2. Prepare product payload
      const payload = { 
        ...productData, 
        business_id: businessId,
        category_id: finalCategoryId
      };

      const result = await productService.createProduct(payload);
      const newProduct = { ...productData, id: result.product?.id || generateId('PRD-') };
      setProducts(prev => [...prev, newProduct]);
      showToast('Product added successfully');
      return result;
    } catch (error) {
      console.error('Add product error:', error);
      if (error.status === 409) throw error; // Re-throw for UI to handle duplication
      showToast(error.message || 'Failed to add product', 'error');
    }
  };

  const updateProduct = async (id, updatedData) => {
    try {
      const payload = { ...updatedData, business_id: businessId };
      if (updatedData.category) {
        const catObj = categories.find(c => c.name === updatedData.category);
        if (catObj) payload.category_id = catObj.id;
      }

      const result = await productService.updateProduct(id, payload);
      setProducts(prev => prev.map(p => p.id === id ? { ...p, ...updatedData } : p));
      showToast('Product updated successfully');
      return result;
    } catch (error) {
      console.error('Update product error:', error);
      showToast(error.message || 'Failed to update product', 'error');
    }
  };

  const deleteProduct = async (id) => {
    try {
      await productService.deleteProduct(id);
      setProducts(prev => prev.filter(p => p.id !== id));
      showToast('Product deleted successfully');
    } catch (error) {
      console.error('Delete product error:', error);
      showToast(error.message || 'Failed to delete product', 'error');
    }
  };

  // CUSTOMERS
  const addCustomer = async (customerData) => {
    try {
      const result = await customerService.createCustomer(customerData);
      setCustomers(prev => [...prev, result.data]);
      showToast('Customer added successfully');
      return result;
    } catch (error) {
      console.error('Add customer error:', error);
      showToast(error.message || 'Failed to add customer', 'error');
    }
  };

  const updateCustomer = async (id, updatedData) => {
    try {
      const result = await customerService.updateCustomer(id, updatedData);
      setCustomers(prev => prev.map(c => c.id === id ? result.data : c));
      showToast('Customer updated successfully');
      return result;
    } catch (error) {
      console.error('Update customer error:', error);
      showToast(error.message || 'Failed to update customer', 'error');
    }
  };

  const deleteCustomer = async (id) => {
    try {
      await customerService.deleteCustomer(id);
      setCustomers(prev => prev.filter(c => c.id !== id));
      showToast('Customer deleted successfully');
    } catch (error) {
      console.error('Delete customer error:', error);
      showToast(error.message || 'Failed to delete customer', 'error');
    }
  };


  // INVENTORY LOG & STOCK SYNC (Bulk Support)
  const addInventoryEntry = async (data) => {
    try {
      const payload = {
        business_id: businessId,
        type: data.type,
        reason: data.reason,
        user_id: user?.id,
        reference_no: data.referenceNo,
        entity_name: data.entityName,
        items: data.items.map(item => ({
          product_id: item.productId,
          variant_name: item.variantName,
          quantity_change: item.quantity,
          unit_price: item.unitPrice,
          total_amount: item.totalAmount,
          type: item.type // Support mixed types per item
        }))
      };
      
      const result = await inventoryService.updateStock(payload);
      
      // Enrich logs for real-time display
      const enrichedLogs = (result.logs || []).map(log => {
        const originalItem = data.items.find(i => 
          i.productId == log.product_id && i.variantName === log.variant_name
        );
        return {
          ...log,
          productName: originalItem?.productName || 'Product',
          variantName: log.variant_name,
          type: log.change_type,
          quantityChange: log.quantity_change,
          stockAfter: log.stock_after,
          doneBy: user?.name || 'Admin',
          date: log.createdAt,
          referenceNo: log.reference_no,
          entityName: log.entity_name,
          unitPrice: log.unit_price,
          totalAmount: log.total_amount
        };
      });

      // Update local state for inventory log
      setInventoryLog(prev => [...enrichedLogs, ...prev]);
      
      // Update local state for product stocks
      setProducts(prevProducts => {
        let updated = [...prevProducts];
        enrichedLogs.forEach(log => {
          updated = updated.map(p => {
            if (p.id === log.product_id) {
              const updatedVariants = (p.variants || []).map(v => {
                if (v.name === log.variant_name) {
                  return { ...v, current_stock: log.stockAfter };
                }
                return v;
              });
              // Update top-level current_stock if it's a standalone product matching the update
              const isStandaloneMatch = p.variants.length === 0 && !log.variant_name;
              return { 
                ...p, 
                current_stock: isStandaloneMatch ? log.stockAfter : p.current_stock,
                variants: updatedVariants 
              };

            }
            return p;
          });
        });
        return updated;
      });

      if (data.reason !== 'Sale') {
        showToast(`Stock updated successfully (${data.items.length} items)`);
      }
      return { ...result, logs: enrichedLogs };
    } catch (error) {
      console.error('Add inventory entry error:', error);
      showToast(error.message || 'Failed to update stock', 'error');
    }
  };

  // TRANSACTIONS (Invoices)
  const addTransaction = async (transaction) => {
    try {
      // Map frontend fields to backend schema
      const payload = {
        business_id: businessId,
        user_id: user?.id,
        customer_id: transaction.customer_id,
        customer_type: transaction.customer_type,
        customer_name: transaction.customerName || 'Walking Customer',
        customer_phone: transaction.customerPhone || '',
        total_amount: transaction.subtotal,
        discount: transaction.discount,
        tax_amount: (transaction.tax || 0) + (transaction.gst || 0),
        final_amount: transaction.total,
        payment_mode: transaction.paymentMode,
        paid_amount: transaction.paidAmount || 0,
        status: 'Paid',
        items: transaction.items.map(item => ({
          productId: item.productId,
          productName: item.name, // Send name to store as snapshot
          variantName: item.variantName,
          quantity: item.quantity,
          price: item.price,
          subtotal: item.price * item.quantity
        }))
      };

      const result = await invoiceService.createInvoice(payload);
      
      // Proper Ledger Management: Record payment entry if cash was received (Matching mobile parity)
      if (transaction.customer_id && transaction.customer_type === 'REGULAR' && transaction.paidAmount > 0) {
        try {
          await paymentService.receivePayment({
            customer_id: transaction.customer_id,
            amount: transaction.paidAmount,
            payment_method: 'Cash',
            note: `Payment received against Invoice #${result.invoice.invoice_number}`,
            date: new Date().toISOString()
          });
        } catch (paymentError) {
          console.error("Ledger sync error:", paymentError);
          // We don't throw here to avoid failing the confirmed invoice, 
          // but the record will be visible after next refresh
        }
      }
      
      // Update local transactions state
      const newTransaction = {
        ...transaction,
        id: result.invoice.invoice_number,
        dbId: result.invoice.id,
        date: result.invoice.createdAt,
        status: result.invoice.status,
        cashierName: user?.name || 'Admin'
      };
      setTransactions(prev => [newTransaction, ...prev]);
      
      // Update local product stock state (sync UI)
      setProducts(prevProducts => {
        let updated = [...prevProducts];
        transaction.items.forEach(item => {
          updated = updated.map(p => {
            if (p.id === item.productId) {
              const updatedVariants = p.variants.map(v => {
                if (v.name === item.variantName) {
                  const currentStock = parseInt(v.stock) || 0;
                  return { ...v, stock: currentStock - item.quantity };
                }
                return v;
              });
              return { ...p, variants: updatedVariants };
            }
            return p;
          });
        });
        return updated;
      });

      // Refresh inventory log
      const logResult = await inventoryService.getInventoryLog(businessId);
      const mappedLogs = (logResult || []).map(log => ({
        id: log.id,
        productId: log.product_id,
        productName: log.product?.name || 'Unknown',
        variantName: log.variant_name,
        type: log.change_type,
        quantityChange: log.quantity_change,
        reason: log.reason,
        stockAfter: log.stock_after,
        doneBy: log.user?.name || 'Admin',
        date: log.createdAt
      }));
      setInventoryLog(mappedLogs);

      showToast('Transaction completed', 'success');
      return newTransaction;
    } catch (error) {
      console.error('Add transaction error:', error);
      showToast(error.message || 'Failed to complete transaction', 'error');
    }
  };

  // SETTINGS
  const updateSettings = async (newSettings) => {
    try {
      // Map back to snake_case for backend
      const payload = {
        business_name: newSettings.businessName,
        gst_number: newSettings.gstNumber,
        business_phone: newSettings.phone,
        business_address: newSettings.address,
        tax_percentage: newSettings.taxPercentage,
        gst_percentage: newSettings.gstPercentage,
        currency: newSettings.currency,
        invoice_prefix: newSettings.invoicePrefix,
        starting_invoice_number: newSettings.startingNumber,
        footer_note: newSettings.footerNote,
        invoice_format: newSettings.invoiceFormat,
        business_logo: newSettings.photo,
        category_compulsory: newSettings.categoryCompulsory,
        variants_enabled: newSettings.variantsEnabled
      };

      const result = await settingsService.updateSettings(businessId, payload);
      
      // Update local state with camelCase
      setSettings(newSettings);
      showToast('Settings saved');
      return result;
    } catch (error) {
      console.error('Update settings error:', error);
      showToast(error.message || 'Failed to save settings', 'error');
    }
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
  const addUom = async (uomData) => {
    try {
      const payload = { ...uomData, business_id: businessId };
      const result = await uomService.createUOM(payload);
      const newUom = { ...uomData, id: result.uom?.id || generateId('UOM-') };
      setUoms(prev => [...prev, newUom]);
      showToast('Unit added successfully');
    } catch (error) {
      console.error('Add UOM error:', error);
      showToast(error.message || 'Failed to add unit', 'error');
    }
  };

  const updateUom = async (id, updates) => {
    try {
      await uomService.updateUOM(id, updates);
      setUoms(prev => prev.map(u => u.id === id ? { ...u, ...updates } : u));
      showToast('Unit updated successfully');
    } catch (error) {
      console.error('Update UOM error:', error);
      showToast(error.message || 'Failed to update unit', 'error');
    }
  };

  const deleteUom = async (id) => {
    try {
      await uomService.deleteUOM(id);
      setUoms(prev => prev.filter(u => u.id !== id));
      showToast('Unit deleted successfully');
    } catch (error) {
      console.error('Delete UOM error:', error);
      showToast(error.message || 'Failed to delete unit', 'error');
    }
  };

  // BUSINESSES
  const addBusiness = async (businessData) => {
    try {
      const result = await businessService.createBusiness(businessData);
      const newBiz = result.business;
      setBusinesses(prev => [...prev, {
        ...newBiz,
        role: 'Admin',
        role_id: newBiz.role_id
      }]);
      showToast('Business created successfully');
      return result;
    } catch (error) {
      console.error('Add business error:', error);
      showToast(error.message || 'Failed to create business', 'error');
    }
  };

  const deleteBusinessStore = async (id) => {
    try {
      await businessService.deleteBusiness(id);
      setBusinesses(prev => prev.filter(b => b.id !== id));
      showToast('Business deleted successfully');
    } catch (error) {
      console.error('Delete business error:', error);
      showToast(error.message || 'Failed to delete business', 'error');
    }
  };

  const value = {
    businesses,
    categories,
    products,
    transactions,
    inventoryLog,
    settings,
    users,
    roles,
    qrCodes,
    loading,
    uoms,
    customers,
    businessId,
    addCategory,
    updateCategory,
    deleteCategory,
    addProduct,
    updateProduct,
    deleteProduct,
    addCustomer,
    updateCustomer,
    deleteCustomer,
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
