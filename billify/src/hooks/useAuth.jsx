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
    // Support "allow any" by defaulting to admin if not found
    let foundUser = Array.isArray(users) ? users.find(u => u.email === email && u.password === password) : null;
    
    if (!foundUser) {
      // Mock user for "any login" request
      foundUser = {
        id: `mock-${Date.now()}`,
        businessId: 'biz_default',
        name: email.split('@')[0] || 'User',
        role: 'Admin',
        email: email
      };
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

  const value = {
    user,
    login,
    logout,
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
