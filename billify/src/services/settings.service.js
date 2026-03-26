import api from './api';

export const settingsService = {
  getSettings: async (businessId) => {
    try {
      const response = await api.get(`/settings/business/${businessId}`);
      return response.data.settings;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch settings' };
    }
  },

  updateSettings: async (businessId, settingsData) => {
    try {
      const response = await api.put(`/settings/business/${businessId}`, settingsData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update settings' };
    }
  }
};
