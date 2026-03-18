import React, { useState } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';

const RevenueChart = ({ transactions = [] }) => {
  const [view, setView] = useState('week');

  // Process Week Data (Last 7 Days)
  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const last7Days = [...Array(7)].map((_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    d.setHours(0,0,0,0);
    return d;
  });

  const weekData = last7Days.map(date => {
    const dayName = weekDays[date.getDay()];
    const nextDay = new Date(date);
    nextDay.setDate(date.getDate() + 1);
    
    const dayTotal = transactions
      .filter(t => {
        const d = new Date(t.date);
        return d >= date && d < nextDay;
      })
      .reduce((acc, t) => acc + t.total, 0);

    return { name: dayName, revenue: dayTotal };
  });

  // Process Month Data (Weeks of current month)
  const currentMonth = new Date().getMonth();
  const currentYear = new Date().getFullYear();
  
  const monthData = [1, 2, 3, 4].map(weekNum => {
    const weekTotal = transactions
      .filter(t => {
        const d = new Date(t.date);
        if (d.getMonth() !== currentMonth || d.getFullYear() !== currentYear) return false;
        const dom = d.getDate();
        if (weekNum === 1) return dom <= 7;
        if (weekNum === 2) return dom > 7 && dom <= 14;
        if (weekNum === 3) return dom > 14 && dom <= 21;
        return dom > 21;
      })
      .reduce((acc, t) => acc + t.total, 0);

    return { name: `Week ${weekNum}`, revenue: weekTotal };
  });

  const data = view === 'week' ? weekData : monthData;

  return (
    <div className="card revenue-chart-card">
      <div className="card-header">
        <h3 className="card-title">Revenue Overview</h3>
        <div className="chart-toggle">
          <button 
            className={`toggle-btn ${view === 'week' ? 'active' : ''}`}
            onClick={() => setView('week')}
          >
            Week
          </button>
          <button 
            className={`toggle-btn ${view === 'month' ? 'active' : ''}`}
            onClick={() => setView('month')}
          >
            Month
          </button>
        </div>
      </div>
      <div className="chart-container">
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data} margin={{ top: 20, right: 0, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
            <XAxis 
              dataKey="name" 
              axisLine={false} 
              tickLine={false} 
              tick={{ fill: '#6b7280', fontSize: 12 }}
              dy={10}
            />
            <YAxis 
              axisLine={false} 
              tickLine={false} 
              tick={{ fill: '#6b7280', fontSize: 12 }}
            />
            <Tooltip 
              cursor={{ fill: '#f9fafb' }}
              contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
            />
            <Bar dataKey="revenue" radius={[4, 4, 0, 0]}>
              {data.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={index === data.length - 1 ? '#0d9488' : '#99f6e4'} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default RevenueChart;
