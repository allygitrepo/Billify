import api from './api';

export const productService = {
  getProducts: async (businessId) => {
    try {
      const response = await api.get(`/products/business/${businessId}`);
      return response.data.products;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch products' };
    }
  },

  createProduct: async (productData) => {
    try {
      const response = await api.post('/products/create', productData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create product' };
    }
  },

  updateProduct: async (id, productData) => {
    try {
      const response = await api.put(`/products/update/${id}`, productData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to update product' };
    }
  },

  deleteProduct: async (id) => {
    try {
      const response = await api.delete(`/products/delete/${id}`);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to delete product' };
    }
  }
};
