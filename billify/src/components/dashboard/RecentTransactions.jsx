import React from 'react';
import { formatCurrency } from '../../utils/formatCurrency';

const RecentTransactions = ({ transactions = [] }) => {
  const recent = [...transactions]
    .sort((a, b) => new Date(b.date) - new Date(a.date))
    .slice(0, 5);

  return (
    <div className="card transactions-card">
      <div className="card-header">
        <h3 className="card-title">Recent Transactions</h3>
      </div>
      <div className="table-responsive">
        <table className="compact-table">
          <thead>
            <tr>
              <th>Invoice</th>
              <th>Items</th>
              <th>Method</th>
              <th>Amount</th>
              <th>Time</th>
            </tr>
          </thead>
          <tbody>
            {recent.map((tx) => (
              <tr key={tx.id}>
                <td className="font-medium">{tx.id.substring(0, 8)}...</td>
                <td>{tx.itemsCount}</td>
                <td>
                  <span className={`type-tag ${tx.paymentMethod.toLowerCase()}`}>
                    {tx.paymentMethod}
                  </span>
                </td>
                <td className="font-bold">{formatCurrency(tx.total)}</td>
                <td className="text-muted">{new Date(tx.date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default RecentTransactions;
