const StockAlerts = ({ products = [], onViewAll }) => {
  const alerts = products.flatMap(p => 
    p.variants
      .filter(v => v.stock <= 10)
      .map((v, index) => ({
        id: `${p.id}-${v.name}-${index}`,
        name: p.name,
        variant: v.name,
        stock: v.stock,
        level: v.stock === 0 ? 'out' : 'low'
      }))
  ).slice(0, 5);

  return (
    <div className="card stock-alerts-card">
      <div className="card-header">
        <h3 className="card-title">Stock Alerts</h3>
        <button className="btn-text" onClick={onViewAll}>View All</button>
      </div>
      <div className="alerts-list">
        {alerts.length > 0 ? (
          alerts.map((item) => (
            <div key={item.id} className="alert-item">
              <div className="alert-info">
                <span className="alert-name">{item.name}</span>
                <span className="alert-variant">{item.variant}</span>
              </div>
              <div className={`alert-badge ${item.level}`}>
                {item.stock === 0 ? 'Out of stock' : `${item.stock} left`}
              </div>
            </div>
          ))
        ) : (
          <div className="empty-alerts" style={{ textAlign: 'center', padding: 'var(--spacing-8) var(--spacing-4)', color: 'var(--neutral-500)' }}>
            <div style={{ fontSize: '2rem', marginBottom: 'var(--spacing-2)' }}>✅</div>
            <p style={{ fontSize: '0.875rem' }}>All products are well-stocked!</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default StockAlerts;
