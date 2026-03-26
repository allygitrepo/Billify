import api from './api';

export const userService = {
  getUsers: async (businessId) => {
    try {
      const response = await api.get(`/users/business/${businessId}`);
      return response.data.users;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch users' };
    }
  },

  createUser: async (userData) => {
    try {
      const response = await api.post('/users/create', userData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create user' };
    }
  },

  updateUser: async (id, userData) => {
    try {
      const response = await api.put(`/users/update/${id}`, userData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update user' };
    }
  },

  deleteUser: async (id, businessId) => {
    try {
      const response = await api.delete(`/users/delete/${id}?business_id=${businessId}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete user' };
    }
  },

  changePassword: async (passwordData) => {
    try {
      const response = await api.post('/users/change-password', passwordData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to change password' };
    }
  },

  updateProfile: async (profileData) => {
    try {
      const response = await api.put('/users/profile/update', profileData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update profile' };
    }
  }
};
