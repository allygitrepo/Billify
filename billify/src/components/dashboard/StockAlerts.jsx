const StockAlerts = ({ products = [] }) => {
  const alerts = products.flatMap(p => 
    p.variants
      .filter(v => v.stock <= 5)
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
        <button className="btn-text">View All</button>
      </div>
      <div className="alerts-list">
        {alerts.map((item) => (
          <div key={item.id} className="alert-item">
            <div className="alert-info">
              <span className="alert-name">{item.name}</span>
              <span className="alert-variant">{item.variant}</span>
            </div>
            <div className={`alert-badge ${item.level}`}>
              {item.stock === 0 ? 'Out of stock' : `${item.stock} left`}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default StockAlerts;
