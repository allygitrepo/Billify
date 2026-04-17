import api from './api';

export const tableService = {
  getTables: async (businessId) => {
    try {
      const response = await api.get(`/tables/business/${businessId}`);
      return response.data.tables;
    } catch (error) {
      console.error('Error fetching tables:', error);
      throw error;
    }
  },

  createTable: async (tableData) => {
    try {
      const response = await api.post('/tables', tableData);
      return response.data;
    } catch (error) {
      console.error('Error creating table:', error);
      throw error;
    }
  },

  deleteTable: async (id) => {
    try {
      const response = await api.delete(`/tables/${id}`);
      return response.data;
    } catch (error) {
      console.error('Error deleting table:', error);
      throw error;
    }
  },

  deleteTablesBulk: async (ids) => {
    try {
      const response = await api.delete('/tables/bulk/delete', { data: { ids } });
      return response.data;
    } catch (error) {
      console.error('Error bulk deleting tables:', error);
      throw error;
    }
  }
};
