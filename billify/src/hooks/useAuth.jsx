import React, { createContext, useContext, useState, useEffect } from 'react';
import { authService } from '../services/auth.service';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const savedUser = localStorage.getItem('billify_user');
    if (savedUser) {
      try {
        const parsed = JSON.parse(savedUser);
        // console.log('useAuth init: loading saved user:', parsed);
        setUser(parsed);
      } catch (error) {
        console.error('Error parsing saved user:', error);
        localStorage.removeItem('billify_user');
      }
    }
    setLoading(false);
  }, []);

  const login = async (email, password) => {
    try {
      // console.log('useAuth: calling authService.login');
      const result = await authService.login(email, password);
      // console.log('useAuth: authService.login result user:', result.user);
      // The service already sets sessionStorage for token and user
      setUser(result.user);
      return { success: true };
    } catch (error) {
      console.error('useAuth: Login error:', error);
      return { success: false, message: error.message || 'Invalid email or password' };
    }
  };

  const register = async (registrationData) => {
    try {
      // Map frontend registration schema to server schema
      const serverPayload = {
        name: registrationData.username,
        email: registrationData.email,
        password: registrationData.password,
        business_name: registrationData.businessName,
        phone: registrationData.phone || '',
        gstin: registrationData.gstNumber || '',
        address: registrationData.address || '',
        userPhoto: registrationData.userPhoto,
        userMobile: registrationData.userMobile,
        businessPhoto: registrationData.businessPhoto,
        taxPercentage: parseFloat(registrationData.taxPercentage) || 0,
        gstPercentage: parseFloat(registrationData.gstPercentage) || 0,
        currency: registrationData.currency || 'INR',
        invoicePrefix: registrationData.invoicePrefix || 'INV',
        startingNumber: parseInt(registrationData.startingNumber) || 1001,
        invoiceFormat: registrationData.invoiceFormat || 'thermal',
        footerNote: registrationData.footerNote || ''
      };

      const result = await authService.register(serverPayload);
      
      // After registration, the user usually needs to log in, 
      // but the server might return the user. Let's redirect to login for simplicity
      // or try to auto-login if the server supports it properly. 
      // Based on my implementation plan, I'll return success and let the component handle it.
      return { success: true, message: result.message };
    } catch (error) {
      console.error('Registration error:', error);
      return { success: false, message: error.message || 'Registration failed' };
    }
  };

  const logout = () => {
    setUser(null);
    authService.logout();
  };

  const switchBusiness = (businessId) => {
    if (!user) return { success: false, message: 'Unauthorized' };
    
    // Find the business in the user's list to get the role
    const businessInfo = user.businesses?.find(b => b.id === businessId);
    const updatedUser = { 
      ...user, 
      businessId, 
      role: businessInfo ? businessInfo.role : user.role 
    };
    
    setUser(updatedUser);
    localStorage.setItem('billify_user', JSON.stringify(updatedUser));
    return { success: true };
  };

  const refreshUser = (newData) => {
    if (!user) return;
    const updatedUser = { ...user, ...newData };
    setUser(updatedUser);
    localStorage.setItem('billify_user', JSON.stringify(updatedUser));
  };

  const value = {
    user,
    businessId: user?.businessId,
    login,
    register,
    logout,
    switchBusiness,
    refreshUser,
    isAuthenticated: !!user,
    loading
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
