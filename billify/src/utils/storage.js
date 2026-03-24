/**
 * Storage utility for Billify
 * Handles localStorage operations with business-level partitioning
 */

const STORAGE_KEY = 'billify_data';

export const getStorageData = () => {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    if (data) return JSON.parse(data);
  } catch (error) {
    console.error('Error parsing storage data:', error);
    // In case of corruption, we continue to seed data
  }

  // Initial Seed Data
  const seedData = {
    users: [
      {
        id: 'user_admin',
        name: 'Admin User',
        email: 'admin@billify.com',
        password: 'password123',
        role: 'Admin',
        businessId: 'biz_default',
        status: 'active'
      }
    ],
    businesses: [
      { id: 'biz_default', name: 'Billify Demo Store' }
    ],
    categories: {
      'biz_default': [
      ]
    },
    products: {
      'biz_default': []
    },
    business_users: {
      'biz_default': []
    },
    roles: {
      'biz_default': []
    },
    inventory_log: {
      'biz_default': []
    },
    transactions: {
      'biz_default': []
    },
    settings: {
      'biz_default': {
        businessName: 'Billify Demo Store',
        gstNumber: '27AAAAA0000A1Z5',
        phone: '9876543210',
        address: '123, Tech Park, Bangalore',
        taxPercentage: '5',
        gstPercentage: '18',
        currency: 'INR',
        invoicePrefix: 'INV',
        startingNumber: '1001',
        footerNote: 'Thank you for shopping with us!',
        invoiceFormat: 'thermal'
      }
    }
  };

  localStorage.setItem(STORAGE_KEY, JSON.stringify(seedData));
  return seedData;
};

export const saveStorageData = (data) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
};

export const getBusinessData = (businessId, entity) => {
  const data = getStorageData();
  return data[entity]?.[businessId] || (entity === 'settings' ? {} : []);
};

export const updateBusinessData = (businessId, entity, updater) => {
  const data = getStorageData();
  if (!data[entity]) data[entity] = {};

  const currentEntityData = data[entity][businessId] || (entity === 'settings' ? {} : []);
  const newData = typeof updater === 'function' ? updater(currentEntityData) : updater;

  data[entity][businessId] = newData;
  saveStorageData(data);
  return newData;
};

// Global Users (for login)
export const getAllUsers = () => {
  return getStorageData().users || [];
};

export const saveUser = (user) => {
  const data = getStorageData();
  const index = data.users.findIndex(u => u.email === user.email);
  if (index !== -1) {
    // Update existing
    data.users[index] = { ...data.users[index], ...user };
  } else {
    // Add new
    data.users.push(user);
  }
  saveStorageData(data);
};

export const deleteGlobalUser = (email) => {
  const data = getStorageData();
  data.users = data.users.filter(u => u.email !== email);
  saveStorageData(data);
};

// Business Management
export const getAllBusinesses = () => {
  return getStorageData().businesses || [];
};

export const addNewBusiness = (businessData) => {
  const data = getStorageData();
  const businessId = `biz_${Date.now()}`;
  
  const newBusiness = { id: businessId, name: businessData.businessName };
  data.businesses.push(newBusiness);
  
  // Initialize empty data for the new business
  data.categories[businessId] = [];
  data.products[businessId] = [];
  data.business_users[businessId] = [];
  data.roles[businessId] = [];
  data.inventory_log[businessId] = [];
  data.transactions[businessId] = [];
  data.settings[businessId] = {
    businessName: businessData.businessName,
    gstNumber: businessData.gstNumber || '',
    phone: businessData.phone || '',
    address: businessData.address || '',
    taxPercentage: '0',
    gstPercentage: '0',
    currency: businessData.currency || 'INR',
    invoicePrefix: 'INV',
    startingNumber: '1',
    footerNote: '',
    invoiceFormat: 'thermal',
    photo: businessData.photo || ''
  };

  saveStorageData(data);
  return newBusiness;
};

export const updateBusinessName = (businessId, newName) => {
  const data = getStorageData();
  const index = data.businesses.findIndex(b => b.id === businessId);
  if (index !== -1) {
    data.businesses[index].name = newName;
    saveStorageData(data);
  }
};

export const deleteBusiness = (businessId) => {
  const data = getStorageData();
  
  // Remove from businesses list
  data.businesses = data.businesses.filter(b => b.id !== businessId);
  
  // Purge all partitioned data
  const entities = ['categories', 'products', 'business_users', 'roles', 'inventory_log', 'transactions', 'settings'];
  entities.forEach(entity => {
    if (data[entity] && data[entity][businessId]) {
      delete data[entity][businessId];
    }
  });

  saveStorageData(data);
};

// Session Management
export const setSession = (session) => {
  localStorage.setItem('billify_session', JSON.stringify(session));
};

export const getSession = () => {
  const session = localStorage.getItem('billify_session');
  return session ? JSON.parse(session) : null;
};

export const clearSession = () => {
  localStorage.removeItem('billify_session');
};
