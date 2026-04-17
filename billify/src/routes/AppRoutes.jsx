import React, { useState } from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import Sidebar from '../components/layout/Sidebar';
import Header from '../components/layout/Header';
import ProtectedRoute from '../components/common/ProtectedRoute';
import { AuthProvider, useAuth } from '../hooks/useAuth';
import { DataProvider, useDataContext } from '../hooks/useDataContext';
import { usePermissions } from '../hooks/usePermissions';

// Pages
import Dashboard from '../pages/dashboard/Dashboard';
import Categories from '../pages/categories/Categories';
import Customers from '../pages/customers/Customers';
import CustomerDetail from '../pages/customers/CustomerDetail';
import Products from '../pages/products/Products';


import Inventory from '../pages/inventory/Inventory';
import POS from '../pages/pos/POS';
import Transactions from '../pages/transactions/Transactions';
import Billing from '../pages/transactions/Billing';
import Users from '../pages/users/Users';
import Settings from '../pages/settings/Settings';
import Uoms from '../pages/settings/Uoms';
import Login from '../pages/auth/Login';
import Register from '../pages/auth/Register';
import Landing from '../pages/landing/Landing';
import Profile from '../pages/profile/Profile';
import BusinessSetup from '../pages/auth/BusinessSetup';
import TableManagement from '../pages/tables/TableManagement';

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

  const { canView } = usePermissions();

  return (
    <div className={`layout-wrapper ${location.pathname === '/billing' ? 'pos-active-layout' : ''}`}>
      <Sidebar isOpen={isSidebarOpen} toggleSidebar={toggleSidebar} isPOS={location.pathname === '/billing'} />
      <div className="main-content" style={location.pathname === '/billing' ? { marginLeft: 0 } : {}}>
        <Header toggleSidebar={toggleSidebar} isPOS={location.pathname === '/billing'} />
        <AnimatePresence mode="wait">
          <Routes location={location} key={location.pathname}>
            <Route path="/dashboard" element={canView('dashboard') ? <PageTransition><Dashboard /></PageTransition> : <Navigate to="/unauthorized" replace />} />
            <Route path="/billing" element={canView('billing') ? <PageTransition><POS /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/categories" element={canView('categories') ? <PageTransition><Categories /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/products" element={canView('products') ? <PageTransition><Products /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/customers" element={canView('customers') ? <PageTransition><Customers /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/customers/:id" element={canView('customers') ? <PageTransition><CustomerDetail /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/inventory" element={canView('inventory') ? <PageTransition><Inventory /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/tables" element={<PageTransition><TableManagement /></PageTransition>} />


            <Route path="/uoms" element={canView('uoms') ? <PageTransition><Uoms /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/transactions" element={canView('transactions') ? <PageTransition><Transactions /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/users" element={canView('users') ? <PageTransition><Users /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/settings" element={canView('settings') ? <PageTransition><Settings /></PageTransition> : <Navigate to="/dashboard" replace />} />
            <Route path="/profile" element={<PageTransition><Profile /></PageTransition>} />
            <Route path="/unauthorized" element={<PageTransition><div style={{padding: '2rem', textAlign: 'center'}}><h2>Access Denied</h2><p>You don't have permission to access this module.</p></div></PageTransition>} />
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
          <Route path="/register" element={<Register />} />
          <Route element={<ProtectedRoute />}>
            <Route path="/business-setup" element={<BusinessSetup />} />
            <Route path="/*" element={<AppLayout />} />
          </Route>
        </Routes>
      </DataProvider>
    </AuthProvider>
  );
};

export default AppRoutes;
