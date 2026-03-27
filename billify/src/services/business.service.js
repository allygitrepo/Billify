import api from './api';

export const businessService = {
  getMyBusinesses: async () => {
    try {
      const response = await api.get('/businesses/my-businesses');
      return response.data.businesses;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch businesses' };
    }
  },

  createBusiness: async (businessData) => {
    try {
      const response = await api.post('/businesses', businessData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create business' };
    }
  },

  updateBusiness: async (id, businessData) => {
    try {
      const response = await api.put(`/businesses/${id}`, businessData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update business' };
    }
  },

  deleteBusiness: async (id) => {
    try {
      const response = await api.delete(`/businesses/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete business' };
    }
  }
};
