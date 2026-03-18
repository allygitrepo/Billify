import { motion, AnimatePresence } from 'framer-motion';
import { NavLink } from 'react-router-dom';

const menuItems = [
  { label: 'Dashboard', icon: '🏠', path: '/' },
  { label: 'POS / Billing', icon: '🧾', path: '/billing' },
  { label: 'Categories', icon: '📁', path: '/categories' },
  { label: 'Products', icon: '📦', path: '/products' },
  { label: 'Inventory', icon: '📊', path: '/inventory' },
  { label: 'Transactions', icon: '💳', path: '/transactions' },
  { label: 'Users & Roles', icon: '👥', path: '/users' },
  { label: 'Settings', icon: '⚙️', path: '/settings' },
];

const Sidebar = ({ isOpen, toggleSidebar }) => {
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
            className="lg-hidden"
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
        className="sidebar-container"
      >
        <div style={{height: '64px', display: 'flex', alignItems: 'center', padding: '0 var(--spacing-6)', borderBottom: '1px solid var(--neutral-50)', backgroundColor: 'var(--primary-50)'}}>
          <span style={{fontSize: '1.5rem', fontWeight: 'bold', color: 'var(--primary-600)'}}>Billify</span>
        </div>

        <nav style={{padding: 'var(--spacing-4)', display: 'flex', flexDirection: 'column', gap: 'var(--spacing-1)', overflowY: 'auto', height: 'calc(100vh - 64px)'}}>
          {menuItems.map((item) => (
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
                textDecoration: 'none',
                backgroundColor: isActive ? 'var(--primary-50)' : 'transparent',
                color: isActive ? 'var(--primary-700)' : 'var(--neutral-500)',
                boxShadow: isActive ? 'var(--shadow-sm)' : 'none',
                position: 'relative',
                overflow: 'hidden'
              })}
              className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}
            >
              <span style={{fontSize: '1.125rem', zIndex: 1}}>{item.icon}</span>
              <span style={{zIndex: 1}}>{item.label}</span>
            </NavLink>
          ))}
        </nav>
      </aside>

      <style>{`
        @media (min-width: 1024px) {
          .sidebar-container {
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
