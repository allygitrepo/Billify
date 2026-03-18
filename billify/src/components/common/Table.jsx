import { motion } from 'framer-motion';
import EmptyState from './EmptyState';

const Table = ({
  columns = [],
  data = [],
  isLoading = false,
  pagination,
  className = ''
}) => {
  if (!isLoading && data.length === 0) {
    return <EmptyState />;
  }

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
            data.map((row, idx) => (
              <motion.tr 
                key={row.id || idx} 
                variants={itemVariants}
                className="table-row-hover"
                style={{borderBottom: '1px solid var(--neutral-100)'}}
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
      
      {pagination && (
        <div style={{padding: 'var(--spacing-4) var(--spacing-6)', backgroundColor: 'white', borderTop: '1px solid var(--neutral-100)', display: 'flex', alignItems: 'center', justifyContent: 'between'}}>
          <span style={{fontSize: '0.875rem', color: 'var(--neutral-500)'}}>
            Page {pagination.current} of {Math.ceil(pagination.total / pagination.pageSize)}
          </span>
          <div style={{display: 'flex', gap: 'var(--spacing-2)'}}>
            <button 
              disabled={pagination.current === 1}
              onClick={() => pagination.onPageChange(pagination.current - 1)}
              className="btn btn-secondary"
              style={{padding: 'var(--spacing-1) var(--spacing-3)', fontSize: '0.75rem'}}
            >
              Previous
            </button>
            <button 
              disabled={pagination.current >= Math.ceil(pagination.total / pagination.pageSize)}
              onClick={() => pagination.onPageChange(pagination.current + 1)}
              className="btn btn-secondary"
              style={{padding: 'var(--spacing-1) var(--spacing-3)', fontSize: '0.75rem'}}
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
