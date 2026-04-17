import api from './api';

export const qrService = {
  getQRByBusiness: async (businessId) => {
    try {
      const response = await api.get(`/qr-codes/business/${businessId}`);
      return response.data.qrCodes;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch QR codes' };
    }
  },
  
  getQRById: async (id) => {
    try {
      const response = await api.get(`/qr-codes/${id}`);
      return response.data.qrCode;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to fetch QR code' };
    }
  },

  createQR: async (data) => {
    try {
      const response = await api.post('/qr-codes', data);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Failed to create QR code' };
    }
  }
};
