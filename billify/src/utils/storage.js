/**
 * Storage utility for Billify
 * Handles localStorage operations with business-level partitioning
 */

const STORAGE_KEY = 'billify_data';

export const getStorageData = () => {
  const data = localStorage.getItem(STORAGE_KEY);
  if (data) return JSON.parse(data);

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
        thermalPrint: true,
        a4Print: false
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
  const index = data.users.findIndex(u => u.id === user.id);
  if (index !== -1) {
    data.users[index] = user;
  } else {
    data.users.push(user);
  }
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
