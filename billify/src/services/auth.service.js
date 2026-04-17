import api from './api';

export const authService = {
  login: async (email, password) => {
    try {
      const response = await api.post('/auth/login', { email, password });
      return authService._handleAuthResponse(response);
    } catch (error) {
      throw error.response?.data || { message: 'Login failed' };
    }
  },

  googleLogin: async (idToken) => {
    try {
      const response = await api.post('/auth/google', { idToken });
      return authService._handleAuthResponse(response);
    } catch (error) {
      throw error.response?.data || { message: 'Google login failed' };
    }
  },

  _handleAuthResponse: (response) => {
    if (response.data.token) {
      localStorage.setItem('billify_token', response.data.token);
      
      const userWithContext = { ...response.data.user };
      if (response.data.businesses && response.data.businesses.length > 0) {
        const lastBusinessId = localStorage.getItem('last_business_id');
        const lastBiz = lastBusinessId ? response.data.businesses.find(b => b.id.toString() === lastBusinessId.toString()) : null;
        
        const activeBiz = lastBiz || response.data.businesses[0];
        
        userWithContext.businessId = activeBiz.id;
        userWithContext.role = activeBiz.role;
        userWithContext.businesses = response.data.businesses;
        
        localStorage.setItem('business_id', activeBiz.id);
        localStorage.setItem('business_name', activeBiz.name);
        localStorage.setItem('last_business_id', activeBiz.id);
      }
      
      localStorage.setItem('billify_user', JSON.stringify(userWithContext));
      return { ...response.data, user: userWithContext };
    }
    return response.data;
  },

  register: async (userData) => {
    try {
      const response = await api.post('/auth/register', userData);
      return response.data;
    } catch (error) {
      throw error.response?.data || { message: 'Registration failed' };
    }
  },

  logout: () => {
    localStorage.removeItem('billify_token');
    localStorage.removeItem('billify_user');
    localStorage.removeItem('business_id');
    localStorage.removeItem('business_name');
  }
};
