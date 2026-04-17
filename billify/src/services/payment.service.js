import api from './api';

export const paymentService = {
  receivePayment: async (paymentData) => {
    try {
      const response = await api.post('/payments/receive', paymentData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to record payment' };
    }
  },

  givePayment: async (paymentData) => {
    try {
      const response = await api.post('/payments/give', paymentData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to record credit entry' };
    }
  },

  deletePayment: async (id) => {
    try {
      const response = await api.delete(`/payments/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete payment' };
    }
  },

  getPaymentHistory: async (params) => {
    try {
      const response = await api.get('/payments', { params });
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch payment history' };
    }
  }
};
