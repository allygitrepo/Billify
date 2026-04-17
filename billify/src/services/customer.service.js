import api from './api';

export const customerService = {
  getCustomers: async (params) => {
    try {
      const response = await api.get('/customers', { params });
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch customers' };
    }
  },

  getCustomerById: async (id) => {
    try {
      const response = await api.get(`/customers/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch customer details' };
    }
  },

  createCustomer: async (customerData) => {
    try {
      const response = await api.post('/customers', customerData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create customer' };
    }
  },

  updateCustomer: async (id, customerData) => {
    try {
      const response = await api.put(`/customers/${id}`, customerData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update customer' };
    }
  },

  deleteCustomer: async (id) => {
    try {
      const response = await api.delete(`/customers/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete customer' };
    }
  },

  getCustomerLedger: async (id) => {
    try {
      const response = await api.get(`/customers/ledger/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch customer ledger' };
    }
  }

};
