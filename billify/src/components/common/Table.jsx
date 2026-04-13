import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import EmptyState from './EmptyState';

const Table = ({
  columns = [],
  data = [],
  isLoading = false,
  className = '',
  showPagination = true,
  onRowClick = null
}) => {

  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  // Reset to first page when data changes (e.g. search/filter)
  useEffect(() => {
    setCurrentPage(1);
  }, [data.length]);

  if (!isLoading && data.length === 0) {
    return <EmptyState />;
  }

  const totalPages = Math.ceil(data.length / pageSize);
  const startIndex = (currentPage - 1) * pageSize;
  const paginatedData = showPagination ? data.slice(startIndex, startIndex + pageSize) : data;

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.05
      }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 }
  };

  return (
    <div className={`table-container ${className}`} style={{overflowX: 'auto', borderRadius: 'var(--radius-lg)', border: '1px solid var(--neutral-100)'}}>
      <table style={{width: '100%', borderCollapse: 'collapse', textAlign: 'left', backgroundColor: 'white'}}>
        <thead style={{backgroundColor: 'var(--neutral-50)', borderBottom: '1px solid var(--neutral-100)'}}>
          <tr>
            {columns.map((col) => (
              <th key={col.key} style={{padding: 'var(--spacing-4) var(--spacing-6)', fontSize: '0.75rem', fontWeight: '600', color: 'var(--neutral-500)', textTransform: 'uppercase', letterSpacing: '0.05em'}}>
                {col.label}
              </th>
            ))}
          </tr>
        </thead>
        <motion.tbody 
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          style={{backgroundColor: 'white'}}
        >
          {isLoading ? (
            <tr>
              <td colSpan={columns.length} style={{padding: 'var(--spacing-8)', textAlign: 'center'}}>
                <div className="spinner" style={{margin: '0 auto', width: '2rem', height: '2rem', color: 'var(--primary-500)'}}></div>
              </td>
            </tr>
          ) : (
            paginatedData.map((row, idx) => (
              <motion.tr 
                key={row.id || idx} 
                variants={itemVariants}
                className={`table-row-hover ${onRowClick ? 'clickable-row' : ''}`}
                style={{borderBottom: '1px solid var(--neutral-100)', cursor: onRowClick ? 'pointer' : 'default'}}
                onClick={() => onRowClick && onRowClick(row)}
              >
                {columns.map((col) => (
                  <td key={col.key} style={{padding: 'var(--spacing-4) var(--spacing-6)', fontSize: '0.875rem', color: 'var(--neutral-700)', whiteSpace: 'nowrap'}}>
                    {col.render ? col.render(row[col.key], row) : row[col.key]}
                  </td>
                ))}
              </motion.tr>
            ))
          )}
        </motion.tbody>
      </table>
      
      {showPagination && data.length > 0 && (
        <div className="table-pagination">
          <div className="pagination-info">
            <div className="pagination-page-size">
              <span>Show</span>
              <select 
                className="pagination-select"
                value={pageSize}
                onChange={(e) => {
                  setPageSize(Number(e.target.value));
                  setCurrentPage(1);
                }}
              >
                <option value={10}>10</option>
                <option value={20}>20</option>
                <option value={30}>30</option>
              </select>
              <span>records</span>
            </div>
            <span>
              Showing {Math.min(data.length, startIndex + 1)} to {Math.min(data.length, startIndex + pageSize)} of {data.length} entries
            </span>
          </div>

          <div className="pagination-controls">
            <button 
              className="pagination-btn"
              disabled={currentPage === 1}
              onClick={() => setCurrentPage(prev => prev - 1)}
            >
              Previous
            </button>
            <span className="pagination-page-indicator">
              {currentPage} / {totalPages || 1}
            </span>
            <button 
              className="pagination-btn"
              disabled={currentPage === totalPages || totalPages === 0}
              onClick={() => setCurrentPage(prev => prev + 1)}
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default Table;
