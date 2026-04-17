import React from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import StatCard from '../../components/dashboard/StatCard';
import RevenueChart from '../../components/dashboard/RevenueChart';
import StockAlerts from '../../components/dashboard/StockAlerts';
import RecentTransactions from '../../components/dashboard/RecentTransactions';
import TopProducts from '../../components/dashboard/TopProducts';
import { formatCurrency } from '../../utils/formatCurrency';
import { Download, QrCode as QrIcon } from 'lucide-react';
import Button from '../../components/common/Button';

const Dashboard = () => {
  const navigate = useNavigate();
  const { transactions, products, qrCodes, settings } = useDataContext();
  
  const profileQr = qrCodes?.find(q => q.qr_type === 'Profile');

  const handleLowStockClick = () => {
    navigate('/products?filter=low_stock');
  };

  // Calculate Metrics
  const today = new Date();
  today.setHours(0,0,0,0);

  const todayTransactions = transactions.filter(t => new Date(t.date) >= today);
  const todaySales = todayTransactions.reduce((acc, t) => acc + t.total, 0);
  const todayOrders = todayTransactions.length;

  const lowStockCount = products.reduce((acc, p) => {
    const minStock = Math.min(...p.variants.map(v => v.stock));
    return minStock <= 10 ? acc + 1 : acc;
  }, 0);

  const thisMonth = new Date().getMonth();
  const monthTransactions = transactions.filter(t => new Date(t.date).getMonth() === thisMonth);
  const monthlyRevenue = monthTransactions.reduce((acc, t) => acc + t.total, 0);

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: { opacity: 1, y: 0 }
  };

  return (
    <PageContainer title="Dashboard Summary">
      <motion.div 
        className="dashboard-grid"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        {/* Stats Row */}
        <motion.div className="stats-row" variants={containerVariants}>
          <motion.div variants={itemVariants}>
            <StatCard 
              title="Total Sales Today" 
              value={formatCurrency(todaySales)} 
              trend="+12%" 
              color="teal"
              icon={
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <line x1="12" y1="1" x2="12" y2="23"></line>
                  <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
                </svg>
              }
            />
          </motion.div>
          <motion.div variants={itemVariants}>
            <StatCard 
              title="Total Orders" 
              value={todayOrders.toString()} 
              trend="+5%" 
              color="purple"
              icon={
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z"></path>
                  <line x1="3" y1="6" x2="21" y2="6"></line>
                  <path d="M16 10a4 4 0 0 1-8 0"></path>
                </svg>
              }
            />
          </motion.div>
          <motion.div variants={itemVariants}>
            <StatCard 
              title="Low Stock Alerts" 
              value={lowStockCount.toString()} 
              trend={lowStockCount > 0 ? "Needs Attention" : "All Items Stocked"} 
              color={lowStockCount > 0 ? "orange" : "teal"}
              onClick={handleLowStockClick}
              icon={
                lowStockCount > 0 ? (
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                    <line x1="12" y1="9" x2="12" y2="13"></line>
                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                  </svg>
                ) : (
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                  </svg>
                )
              }
            />
          </motion.div>
          <motion.div variants={itemVariants}>
            <StatCard 
              title="Monthly Revenue" 
              value={formatCurrency(monthlyRevenue)} 
              trend="+18%" 
              color="blue"
              icon={
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path>
                  <path d="M22 12A10 10 0 0 0 12 2v10z"></path>
                </svg>
              }
            />
          </motion.div>
        </motion.div>

        {/* Main Section */}
        <div className="dashboard-main-content">
          <motion.div className="dashboard-left-col" variants={itemVariants}>
            <RevenueChart transactions={transactions} />
            <RecentTransactions transactions={transactions} />
          </motion.div>
          <motion.div className="dashboard-right-col" variants={itemVariants}>
            {profileQr && (
              <div className="card mb-8" style={{ padding: 'var(--spacing-6)', textAlign: 'center', background: 'linear-gradient(135deg, white 0%, var(--neutral-50) 100%)', position: 'relative', overflow: 'hidden' }}>
                <div style={{ position: 'absolute', top: '-10px', right: '-10px', width: '60px', height: '60px', backgroundColor: 'var(--primary-50)', borderRadius: '50%', opacity: 0.5 }}></div>
                
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: 'var(--spacing-5)', color: 'var(--neutral-800)', position: 'relative' }}>
                  <div style={{ padding: '6px', backgroundColor: 'var(--primary-600)', borderRadius: '8px', color: 'white' }}>
                    <QrIcon size={16} strokeWidth={2.5} />
                  </div>
                  <h3 style={{ fontSize: '0.825rem', fontWeight: '800', textTransform: 'uppercase', letterSpacing: '0.075em' }}>Business Card</h3>
                </div>
                
                <div style={{ 
                  width: '160px', 
                  height: '160px', 
                  margin: '0 auto var(--spacing-4)', 
                  padding: '12px',
                  backgroundColor: 'white',
                  border: '1px solid var(--neutral-100)',
                  borderRadius: '16px',
                  boxShadow: 'var(--shadow-sm)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center'
                }}>
                  <img src={profileQr.qr_data} alt="Business QR" style={{ width: '100%', height: '100%' }} />
                </div>
                
                <div style={{ marginBottom: 'var(--spacing-5)' }}>
                  <p style={{ fontSize: '0.925rem', fontWeight: '700', color: 'var(--neutral-900)', marginBottom: '2px' }}>
                    {settings.businessName || 'Business Profile'}
                  </p>
                  <p style={{ fontSize: '0.7rem', color: 'var(--neutral-400)', fontWeight: '600', letterSpacing: '0.02em' }}>
                    Official Digital Identity
                  </p>
                </div>
                
                <Button 
                  variant="secondary" 
                  size="sm" 
                  className="w-full"
                  onClick={() => {
                    const link = document.createElement('a');
                    link.href = profileQr.qr_data;
                    link.download = `${settings.businessName || 'Business'}_QR.png`;
                    link.click();
                  }}
                  style={{ gap: '8px', fontSize: '0.75rem', height: '40px', borderRadius: '10px', border: '1px solid var(--neutral-200)' }}
                >
                  <Download size={15} /> Save to Device
                </Button>
              </div>
            )}
            <StockAlerts products={products} onViewAll={handleLowStockClick} />
            <TopProducts transactions={transactions} />
          </motion.div>
        </div>
      </motion.div>
    </PageContainer>
  );
};

export default Dashboard;
