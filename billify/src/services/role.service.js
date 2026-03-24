import api from './api';

export const roleService = {
  getRoles: async (businessId) => {
    try {
      const response = await api.get(`/roles/business/${businessId}`);
      return response.data.roles;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch roles' };
    }
  },

  createRole: async (roleData) => {
    try {
      const response = await api.post('/roles/create', roleData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create role' };
    }
  },

  updateRole: async (id, roleData) => {
    try {
      const response = await api.put(`/roles/update/${id}`, roleData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update role' };
    }
  },

  deleteRole: async (id) => {
    try {
      const response = await api.delete(`/roles/delete/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete role' };
    }
  }
};
