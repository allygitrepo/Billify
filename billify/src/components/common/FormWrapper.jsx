import { motion } from 'framer-motion';

const FormWrapper = ({ title, children, onSubmit, onCancel, submitLabel = 'Save' }) => {
  return (
    <motion.div 
      className="card" 
      style={{marginBottom: 'var(--spacing-6)'}}
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      transition={{ duration: 0.3 }}
    >
      {title && <h2 style={{fontSize: '1.125rem', fontWeight: '600', color: 'var(--neutral-800)', marginBottom: 'var(--spacing-6)'}}>{title}</h2>}
      <form 
        onSubmit={(e) => {
          e.preventDefault();
          onSubmit();
        }}
      >
        <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 'var(--spacing-6)', marginBottom: 'var(--spacing-8)'}}>
          {children}
        </div>
        <div style={{display: 'flex', justifyContent: 'flex-end', gap: 'var(--spacing-3)', borderTop: '1px solid var(--neutral-100)', paddingTop: 'var(--spacing-6)'}}>
          {onCancel && (
            <button
              type="button"
              onClick={onCancel}
              style={{backgroundColor: 'transparent', border: 'none', padding: 'var(--spacing-2) var(--spacing-4)', fontSize: '0.875rem', fontWeight: '500', color: 'var(--neutral-500)', cursor: 'pointer'}}
            >
              Cancel
            </button>
          )}
          <button
            type="submit"
            className="btn btn-primary"
            style={{padding: 'var(--spacing-2) var(--spacing-6)'}}
          >
            {submitLabel}
          </button>
        </div>
      </form>
    </motion.div>
  );
};

export default FormWrapper;
