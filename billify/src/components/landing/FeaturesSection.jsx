import React from 'react';

const features = [
  { title: 'Fast POS Billing', desc: 'Generate invoices in seconds with our optimized point-of-sale interface.' },
  { title: 'Inventory Tracking', desc: 'Real-time stock updates and low-stock alerts to keep your business running.' },
  { title: 'Multi-User Access', desc: 'Manage roles and permissions for your staff across multiple locations.' },
  { title: 'GST & Tax Management', desc: 'Automatic tax calculations and GST-compliant invoicing for India.' },
  { title: 'Reports & Analytics', desc: 'Gain insights into your sales, profits, and top-selling products.' },
  { title: 'Bulk Product Upload', desc: 'Save time by uploading your entire product catalog using Excel.' },
];

const FeaturesSection = () => {
  return (
    <section className="features-section" id="features">
      <div className="container">
        <div className="section-header">
          <h2 className="section-title">Powerful Features for Your Business</h2>
          <p className="section-subtitle">Everything you need to manage your business efficiently in one place.</p>
        </div>
        <div className="features-grid">
          {features.map((feature, idx) => (
            <div key={idx} className="feature-card">
              <div className="feature-icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
                </svg>
              </div>
              <h3 className="feature-title">{feature.title}</h3>
              <p className="feature-desc">{feature.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;
