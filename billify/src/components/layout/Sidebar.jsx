import { motion, AnimatePresence } from 'framer-motion';
import { NavLink } from 'react-router-dom';
import { usePermissions } from '../../hooks/usePermissions';
import Logo from '../common/Logo';

const menuItems = [
  { id: 'dashboard', label: 'Dashboard', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>, path: '/dashboard' },
  { id: 'billing', label: 'POS / Billing', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>, path: '/billing' },
  { id: 'categories', label: 'Categories', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path></svg>, path: '/categories' },
  { id: 'products', label: 'Products', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21"></line><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>, path: '/products' },
   { id: 'inventory', label: 'Inventory', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line></svg>, path: '/inventory' },
   { id: 'tables', label: 'Restaurant Tables', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M2 12h20"></path><path d="M10 16v4"></path><path d="M14 16v4"></path><path d="M4 12v8"></path><path d="M20 12v8"></path><path d="M5 4h14a2 2 0 0 1 2 2v6H3V6a2 2 0 0 1 2-2z"></path></svg>, path: '/tables' },
   { id: 'uoms', label: 'Unit of Measurements', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 2v20c-5 0-9-4-9-10s4-10 9-10z"></path><path d="M18 10h3"></path><path d="M18 14h3"></path><path d="M18 6h3"></path><path d="M13 10h3"></path><path d="M13 14h3"></path><path d="M13 6h3"></path></svg>, path: '/uoms' },
  { id: 'transactions', label: 'Transactions', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect><line x1="1" y1="10" x2="23" y2="10"></line></svg>, path: '/transactions' },
  { id: 'customers', label: 'Customers', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>, path: '/customers' },
  { id: 'users', label: 'Users & Roles', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>, path: '/users' },

  { id: 'settings', label: 'Settings', icon: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>, path: '/settings' },
];

const Sidebar = ({ isOpen, toggleSidebar, isPOS }) => {
  const { canView } = usePermissions();

  const filteredMenuItems = menuItems.filter(item => {
    if (item.id === 'dashboard') return true; 
    return canView(item.id);
  });
  return (
    <>
      {/* Mobile Overlay */}
      <AnimatePresence>
        {isOpen && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            style={{
              position: 'fixed',
              inset: '0',
              backgroundColor: 'rgba(0, 0, 0, 0.5)',
              zIndex: '40'
            }}
            className={isPOS ? "" : "lg-hidden"}
            onClick={toggleSidebar}
          />
        )}
      </AnimatePresence>

      <aside 
        style={{
          position: 'fixed',
          insetY: '0',
          left: '0',
          height: '100vh',
          backgroundColor: 'white',
          borderRight: '1px solid var(--neutral-100)',
          width: '256px',
          zIndex: '50',
          transition: 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
          transform: isOpen ? 'translateX(0)' : 'translateX(-100%)'
        }}
        className={`sidebar-container ${isPOS ? 'pos-sidebar' : ''}`}
      >
        <div style={{height: '64px', display: 'flex', alignItems: 'center', gap: '10px', padding: '0 var(--spacing-6)', borderBottom: '1px solid var(--neutral-50)', backgroundColor: 'var(--primary-50)'}}>
          <Logo />
        </div>

        <nav style={{padding: 'var(--spacing-4)', display: 'flex', flexDirection: 'column', gap: 'var(--spacing-1)', overflowY: 'auto', height: 'calc(100vh - 64px)'}}>
          {filteredMenuItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              onClick={() => window.innerWidth < 1024 && toggleSidebar()}
              style={({ isActive }) => ({
                display: 'flex',
                alignItems: 'center',
                gap: 'var(--spacing-3)',
                padding: 'var(--spacing-3) var(--spacing-4)',
                borderRadius: 'var(--radius-lg)',
                fontSize: '0.875rem',
                fontWeight: '500',
                fontStyle: 'normal',
                textDecoration: 'none',
                backgroundColor: isActive ? 'var(--primary-50)' : 'transparent',
                color: isActive ? 'var(--primary-700)' : 'var(--neutral-500)',
                boxShadow: isActive ? 'var(--shadow-sm)' : 'none',
                position: 'relative',
                overflow: 'hidden'
              })}
              className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}
            >
              <span style={{display: 'flex', alignItems: 'center', zIndex: 1}}>{item.icon}</span>
              <span style={{zIndex: 1}}>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>

      <style>{`
        @media (min-width: 1024px) {
          .sidebar-container:not(.pos-sidebar) {
            transform: translateX(0) !important;
          }
          .lg-hidden {
            display: none !important;
          }
        }
        
        .sidebar-link:hover:not(.active) {
          background-color: var(--neutral-50) !important;
          color: var(--neutral-800) !important;
          transform: translateX(4px);
        }
        
        .sidebar-link.active::before {
          content: "";
          position: absolute;
          left: 0;
          top: 20%;
          bottom: 20%;
          width: 4px;
          background-color: var(--primary-600);
          border-radius: 0 4px 4px 0;
        }
      `}</style>
    </>
  );
};

export default Sidebar;
