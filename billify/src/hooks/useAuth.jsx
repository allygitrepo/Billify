import React, { createContext, useContext, useState, useEffect } from 'react';
import { getSession, setSession, clearSession, getAllUsers } from '../utils/storage';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const session = getSession();
    if (session) {
      setUser(session);
    }
    setLoading(false);
  }, []);

  const login = (email, password) => {
    const users = getAllUsers();
    const foundUser = Array.isArray(users) ? users.find(u => u.email === email && u.password === password) : null;
    
    if (!foundUser) {
      return { success: false, message: 'Invalid email or password' };
    }

    if (foundUser.status === 'inactive') {
      return { success: false, message: 'This account has been disabled' };
    }
    
    const sessionData = {
      id: foundUser.id,
      businessId: foundUser.businessId,
      name: foundUser.name,
      role: foundUser.role,
      email: foundUser.email
    };
    
    setUser(sessionData);
    setSession(sessionData);
    return { success: true };
  };

  const logout = () => {
    setUser(null);
    clearSession();
  };

  const switchBusiness = (businessId) => {
    if (!user || user.role !== 'Admin') return { success: false, message: 'Unauthorized' };
    const updatedUser = { ...user, businessId };
    setUser(updatedUser);
    setSession(updatedUser);
    return { success: true };
  };

  const value = {
    user,
    businessId: user?.businessId,
    login,
    logout,
    switchBusiness,
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
