import api from './api';

export const invoiceService = {
  getInvoices: async (businessId) => {
    try {
      const response = await api.get(`/invoices/business/${businessId}`);
      return response.data.invoices;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch invoices' };
    }
  },

  createInvoice: async (invoiceData) => {
    try {
      const response = await api.post('/invoices/create', invoiceData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create invoice' };
    }
  }
};
