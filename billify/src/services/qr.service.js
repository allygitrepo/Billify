import api from './api';

export const qrService = {
  getBusinessQR: async (businessId, type = 'business_profile') => {
    try {
      const response = await api.get(`/qr-codes/${businessId}?type=${type}`);
      return response.data.qrCode;
    } catch (error) {
      if (error.response && error.response.status === 404) {
        return null;
      }
      console.error('Error fetching QR code:', error);
      throw error;
    }
  }
};
