import api from './api';

export const categoryService = {
  getCategories: async (businessId) => {
    try {
      const response = await api.get(`/categories/business/${businessId}`);
      return response.data.categories;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch categories' };
    }
  },

  createCategory: async (categoryData) => {
    try {
      const response = await api.post('/categories/create', categoryData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create category' };
    }
  },

  updateCategory: async (id, categoryData) => {
    try {
      const response = await api.put(`/categories/update/${id}`, categoryData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update category' };
    }
  },

  deleteCategory: async (id) => {
    try {
      const response = await api.delete(`/categories/delete/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete category' };
    }
  }
};
