import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add a request interceptor to add the auth token to every request
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('billify_token');
    // console.log(`API Request: ${config.method.toUpperCase()} ${config.url}`, { hasToken: !!token });
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    console.error('API Request Error:', error);
    return Promise.reject(error);
  }
);

// Add a response interceptor to handle token expiration
api.interceptors.response.use(
  (response) => {
    // console.log(`API Response: ${response.config.method.toUpperCase()} ${response.config.url} - ${response.status}`);
    return response;
  },
  (error) => {
    const isAuthPage = window.location.pathname.includes('/login') || window.location.pathname.includes('/register');
    console.error(`API Error: ${error.config?.method.toUpperCase()} ${error.config?.url} - ${error.response?.status}`, error.response?.data);
    
    if (error.response && error.response.status === 401 && !isAuthPage) {
      // Only redirect if NOT already on an auth page, to avoid loops
      console.warn('Unauthorized! Redirecting to login...');
      localStorage.removeItem('billify_token');
      localStorage.removeItem('billify_user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
