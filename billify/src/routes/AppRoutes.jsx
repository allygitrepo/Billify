import React, { useState } from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import Sidebar from '../components/layout/Sidebar';
import Header from '../components/layout/Header';
import ProtectedRoute from '../components/common/ProtectedRoute';
import { AuthProvider } from '../hooks/useAuth';
import { DataProvider } from '../hooks/useDataContext';

// Pages
import Dashboard from '../pages/dashboard/Dashboard';
import Categories from '../pages/categories/Categories';
import Products from '../pages/products/Products';
import Inventory from '../pages/inventory/Inventory';
import POS from '../pages/pos/POS';
import Transactions from '../pages/transactions/Transactions';
import Billing from '../pages/transactions/Billing';
import Users from '../pages/users/Users';
import Settings from '../pages/settings/Settings';
import Login from '../pages/auth/Login';
import Landing from '../pages/landing/Landing';

const PageTransition = ({ children }) => (
  <motion.div
    initial={{ opacity: 0, y: 10 }}
    animate={{ opacity: 1, y: 0 }}
    exit={{ opacity: 0, y: -10 }}
    transition={{ duration: 0.2 }}
  >
    {children}
  </motion.div>
);

const AppLayout = () => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);
  const location = useLocation();

  return (
    <div className="layout-wrapper">
      <Sidebar isOpen={isSidebarOpen} toggleSidebar={toggleSidebar} />
      <div className="main-content">
        <Header toggleSidebar={toggleSidebar} />
        <AnimatePresence mode="wait">
          <Routes location={location} key={location.pathname}>
            <Route path="/dashboard" element={<PageTransition><Dashboard /></PageTransition>} />
            <Route path="/billing" element={<PageTransition><POS /></PageTransition>} />
            <Route path="/categories" element={<PageTransition><Categories /></PageTransition>} />
            <Route path="/products" element={<PageTransition><Products /></PageTransition>} />
            <Route path="/inventory" element={<PageTransition><Inventory /></PageTransition>} />
            <Route path="/transactions" element={<PageTransition><Transactions /></PageTransition>} />
            <Route path="/users" element={<PageTransition><Users /></PageTransition>} />
            <Route path="/settings" element={<PageTransition><Settings /></PageTransition>} />
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </AnimatePresence>
      </div>
    </div>
  );
};

const AppRoutes = () => {
  return (
    <AuthProvider>
      <DataProvider>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/login" element={<Login />} />
          <Route element={<ProtectedRoute />}>
            <Route path="/*" element={<AppLayout />} />
          </Route>
        </Routes>
      </DataProvider>
    </AuthProvider>
  );
};

export default AppRoutes;
