import React, { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { useDataContext } from '../../hooks/useDataContext';

const Header = ({ toggleSidebar, isPOS }) => {
  const { user, logout, switchBusiness } = useAuth();
  const { businesses } = useDataContext();
  const navigate = useNavigate();
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const dropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setIsDropdownOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <header style={{height: '64px', backgroundColor: 'white', borderBottom: '1px solid var(--neutral-100)', display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 var(--spacing-6)', position: 'sticky', top: '0', zIndex: '30'}}>
      <button 
        style={{backgroundColor: 'transparent', border: 'none', color: 'var(--neutral-500)', cursor: 'pointer', padding: 'var(--spacing-2)'}}
        className={isPOS ? "" : "lg-hidden"}
        onClick={toggleSidebar}
      >
          <svg style={{width: '24px', height: '24px'}} fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
      <div style={{flex: '1'}} className={isPOS ? "" : "lg-ml-0"}>
        <h1 style={{fontSize: '0.75rem', fontWeight: '600', color: 'var(--neutral-500)', textTransform: 'uppercase', letterSpacing: '0.05em'}} className="header-welcome">
          {(businesses.find(b => b.id === user?.businessId)?.name || user?.businessName || 'Billify')} / {user?.name || 'Admin'}
        </h1>
      </div>

      <div style={{display: 'flex', alignItems: 'center', gap: 'var(--spacing-4)'}}>
        {user?.role === 'Admin' && businesses.length > 1 && (
          <div className="business-switcher">
            <select 
              value={user.businessId} 
              onChange={(e) => switchBusiness(e.target.value)}
              style={{
                padding: '6px 12px',
                borderRadius: '8px',
                border: '1px solid var(--neutral-200)',
                fontSize: '0.8125rem',
                fontWeight: '600',
                backgroundColor: 'var(--neutral-50)',
                color: 'var(--neutral-700)',
                cursor: 'pointer',
                outline: 'none',
                boxShadow: 'var(--shadow-sm)'
              }}
            >
              {businesses.map(biz => (
                <option key={biz.id} value={biz.id}>{biz.name}</option>
              ))}
            </select>
          </div>
        )}
        <div style={{position: 'relative'}} className="user-profile" ref={dropdownRef}>
          <button 
            style={{display: 'flex', alignItems: 'center', gap: 'var(--spacing-2)', padding: 'var(--spacing-2)', border: 'none', backgroundColor: 'transparent', cursor: 'pointer', borderRadius: 'var(--radius-lg)'}} 
            onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'var(--neutral-50)'} 
            onMouseOut={(e) => isDropdownOpen ? null : e.currentTarget.style.backgroundColor = 'transparent'}
            onClick={() => setIsDropdownOpen(!isDropdownOpen)}
          >
            <div style={{width: '32px', height: '32px', borderRadius: '50%', backgroundColor: 'var(--primary-100)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-700)', fontWeight: 'bold', overflow: 'hidden'}}>
              {user?.photo ? (
                <img src={user.photo} alt="User" style={{width: '100%', height: '100%', objectFit: 'cover'}} />
              ) : (
                user?.name?.charAt(0).toUpperCase() || 'A'
              )}
            </div>
            <span style={{fontSize: '0.875rem', fontWeight: '500', color: 'var(--neutral-700)'}} className="sm-inline">
              {user?.name || 'Admin User'}
            </span>
            <svg style={{width: '16px', height: '16px', color: 'var(--neutral-300)', transition: 'transform 0.2s', transform: isDropdownOpen ? 'rotate(180deg)' : 'none'}} fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {isDropdownOpen && (
            <div style={{
              position: 'absolute',
              top: '100%',
              right: '0',
              marginTop: '8px',
              width: '200px',
              backgroundColor: 'white',
              borderRadius: 'var(--radius-lg)',
              boxShadow: 'var(--shadow-md)',
              border: '1px solid var(--neutral-100)',
              padding: 'var(--spacing-2) 0',
              zIndex: 50
            }}>
              <div style={{
                padding: 'var(--spacing-2) var(--spacing-4)',
                borderBottom: '1px solid var(--neutral-100)',
                marginBottom: 'var(--spacing-2)'
              }}>
                <p style={{margin: 0, fontSize: '0.875rem', fontWeight: '600', color: 'var(--neutral-800)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'}}>
                  {user?.name || 'Admin User'}
                </p>
                <p style={{margin: 0, fontSize: '0.75rem', color: 'var(--neutral-500)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'}}>
                  {user?.email || 'admin@example.com'}
                </p>
              </div>
              <button
                onClick={() => { navigate('/profile'); setIsDropdownOpen(false); }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--spacing-2)',
                  width: '100%',
                  padding: 'var(--spacing-2) var(--spacing-4)',
                  border: 'none',
                  backgroundColor: 'transparent',
                  color: 'var(--neutral-700)',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  cursor: 'pointer',
                  textAlign: 'left'
                }}
                onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'var(--neutral-50)'}
                onMouseOut={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                  <circle cx="12" cy="7" r="4"></circle>
                </svg>
                My Profile
              </button>
              <button
                onClick={handleLogout}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--spacing-2)',
                  width: '100%',
                  padding: 'var(--spacing-2) var(--spacing-4)',
                  border: 'none',
                  backgroundColor: 'transparent',
                  color: 'var(--danger-600)',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  cursor: 'pointer',
                  textAlign: 'left'
                }}
                onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'var(--danger-50)'}
                onMouseOut={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                  <polyline points="16 17 21 12 16 7"></polyline>
                  <line x1="21" y1="12" x2="9" y2="12"></line>
                </svg>
                Logout
              </button>
            </div>
          )}
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
