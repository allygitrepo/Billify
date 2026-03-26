import api from './api';

export const inventoryService = {
  getInventoryLog: async (businessId) => {
    try {
      const response = await api.get(`/inventory/business/${businessId}`);
      return response.data.logs;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch inventory logs' };
    }
  },

  updateStock: async (stockData) => {
    try {
      const response = await api.post('/inventory/update-stock', stockData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update stock' };
    }
  }
};
