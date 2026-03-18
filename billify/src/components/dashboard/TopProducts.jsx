import React from 'react';
import { formatCurrency } from '../../utils/formatCurrency';

const TopProducts = ({ transactions = [] }) => {
  const salesMap = {};
  transactions.forEach(t => {
    t.items.forEach(item => {
      salesMap[item.name] = (salesMap[item.name] || 0) + (item.price * item.quantity);
    });
  });

  const sortedProducts = Object.entries(salesMap)
    .map(([name, sales]) => ({ name, sales }))
    .sort((a, b) => b.sales - a.sales)
    .slice(0, 5);

  const maxSales = sortedProducts[0]?.sales || 1;
  const products = sortedProducts.map(p => ({
    ...p,
    percentage: (p.sales / maxSales) * 100
  }));

  return (
    <div className="card top-products-card">
      <div className="card-header">
        <h3 className="card-title">Top Selling Products</h3>
      </div>
      <div className="products-progess-list">
        {products.map((product, index) => (
          <div key={index} className="product-progress-item">
            <div className="product-progress-info">
              <span className="product-name">{product.name}</span>
              <span className="product-sales">{formatCurrency(product.sales)}</span>
            </div>
            <div className="progress-bar-bg">
              <div 
                className="progress-bar-fill" 
                style={{ width: `${product.percentage}%` }}
              ></div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default TopProducts;
