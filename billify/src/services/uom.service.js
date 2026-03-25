import api from './api';

export const uomService = {
  getUOMs: async (businessId) => {
    try {
      const response = await api.get(`/uoms/business/${businessId}`);
      return response.data.uoms;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch UOMs' };
    }
  },

  createUOM: async (uomData) => {
    try {
      const response = await api.post('/uoms/create', uomData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create UOM' };
    }
  },

  updateUOM: async (id, uomData) => {
    try {
      const response = await api.put(`/uoms/update/${id}`, uomData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update UOM' };
    }
  },

  deleteUOM: async (id) => {
    try {
      const response = await api.delete(`/uoms/delete/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete UOM' };
    }
  }
};
