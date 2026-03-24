import api from './api';

export const businessService = {
  getMyBusinesses: async () => {
    try {
      const response = await api.get('/businesses/my-businesses');
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch businesses' };
    }
  }
};
