import React from 'react';

const StatCard = ({ title, value, trend, icon, color }) => {
  const isPositive = trend && trend.startsWith('+');
  
  return (
    <div className={`stat-card ${color}`}>
      <div className="stat-card-body">
        <div className="stat-info">
          <span className="stat-title">{title}</span>
          <h3 className="stat-value">{value}</h3>
          {trend && (
            <span className={`stat-trend ${isPositive ? 'positive' : 'negative'}`}>
              {trend} <span className="trend-label">vs yesterday</span>
            </span>
          )}
        </div>
        <div className="stat-icon-wrapper">
          {icon}
        </div>
      </div>
    </div>
  );
};

export default StatCard;
