import React from 'react';

const Header = ({ toggleSidebar }) => {
  return (
    <header style={{height: '64px', backgroundColor: 'white', borderBottom: '1px solid var(--neutral-100)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 var(--spacing-6)', position: 'sticky', top: '0', zIndex: '30'}}>
      <button 
        style={{backgroundColor: 'transparent', border: 'none', color: 'var(--neutral-500)', cursor: 'pointer', padding: 'var(--spacing-2)'}}
        className="lg-hidden"
        onClick={toggleSidebar}
      >
        <svg style={{width: '24px', height: '24px'}} fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      <div style={{flex: '1'}} className="lg-ml-0">
        <h1 style={{fontSize: '0.75rem', fontWeight: '600', color: 'var(--neutral-500)', textTransform: 'uppercase', letterSpacing: '0.05em'}} className="header-welcome">
          Welcome back, Admin
        </h1>
      </div>

      <div style={{display: 'flex', alignItems: 'center', gap: 'var(--spacing-4)'}}>
        <div style={{position: 'relative'}} className="user-profile">
          <button style={{display: 'flex', alignItems: 'center', gap: 'var(--spacing-2)', padding: 'var(--spacing-2)', border: 'none', backgroundColor: 'transparent', cursor: 'pointer', borderRadius: 'var(--radius-lg)'}} onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'var(--neutral-50)'} onMouseOut={(e) => e.currentTarget.style.backgroundColor = 'transparent'}>
            <div style={{width: '32px', height: '32px', borderRadius: '50%', backgroundColor: 'var(--primary-100)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-700)', fontWeight: 'bold'}}>
              A
            </div>
            <span style={{fontSize: '0.875rem', fontWeight: '500', color: 'var(--neutral-700)'}} className="sm-inline">Admin User</span>
            <svg style={{width: '16px', height: '16px', color: 'var(--neutral-300)'}} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>
        </div>
      </div>

      <style>{`
        @media (max-width: 1024px) {
          .header-welcome {
            display: none;
          }
          .lg-ml-0 {
            margin-left: var(--spacing-4);
          }
        }
        @media (max-width: 640px) {
          .sm-inline {
            display: none;
          }
        }
      `}</style>
    </header>
  );
};

export default Header;
