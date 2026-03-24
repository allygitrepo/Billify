import React, { useState } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { formatCurrency } from '../../utils/formatCurrency';

/* ── Variant Picker Modal ── */
const VariantModal = ({ product, onClose, onSelect }) => {
  const availableVariants = product.variants.filter(v => v.status === 'active' && v.stock > 0);

  return createPortal(
    <AnimatePresence>
      <div className="modal-root">
        <motion.div
          className="modal-overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
        />
        <motion.div
          className="modal-container"
          style={{ maxWidth: '420px' }}
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          transition={{ type: 'spring', damping: 25, stiffness: 300 }}
        >
          {/* Header */}
          <div className="modal-header">
            <h3 className="modal-title">Select Variant — {product.name}</h3>
            <button className="modal-close-btn" onClick={onClose} aria-label="Close">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>

          {/* Product image + name */}
          <div className="modal-content" style={{ paddingBottom: '1.5rem' }}>
            {product.photo && (
              <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
                <img
                  src={product.photo}
                  alt={product.name}
                  style={{ width: '80px', height: '80px', objectFit: 'cover', borderRadius: '12px', border: '1px solid var(--neutral-100)' }}
                />
              </div>
            )}

            {availableVariants.length === 0 ? (
              <p style={{ textAlign: 'center', color: 'var(--neutral-500)', padding: '1rem 0' }}>
                No variants available in stock.
              </p>
            ) : (
              <div className="variant-picker-list">
                {availableVariants.map(v => (
                  <motion.button
                    key={v.id || v.name}
                    className="variant-picker-item"
                    whileTap={{ scale: 0.97 }}
                    onClick={() => {
                      onSelect(product, v);
                      onClose();
                    }}
                  >
                    <div className="variant-picker-info">
                      <span className="variant-picker-name">{v.name}</span>
                      <span className="variant-picker-sku" style={{ fontSize: '0.75rem', color: 'var(--neutral-400)' }}>{v.sku}</span>
                    </div>
                    <div className="variant-picker-meta">
                      <span className="variant-picker-price">{formatCurrency(v.price)}</span>
                      <span className={`variant-picker-stock ${v.stock <= 5 ? 'low' : ''}`}>
                        {v.stock} left
                      </span>
                    </div>
                  </motion.button>
                ))}
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>,
    document.body
  );
};

/* ── Product Grid ── */
const ProductGrid = ({ products, categories: allCategories, activeCategory, onCategoryChange, onAddToCart, searchTerm = '' }) => {
  const [selectedProduct, setSelectedProduct] = useState(null);

  // Use all categories from the app context, not just the ones with products
  const categoryNames = ['All', ...(allCategories?.map(c => c.name) || [])];

  const searchLower = searchTerm.toLowerCase();

  const filteredProducts = (activeCategory === 'All'
    ? products
    : products.filter(p => p.category === activeCategory)
  ).filter(p => {
    if (p.status !== 'active') return false;
    
    // Check if it has any active, in-stock variants
    const hasActiveVariants = p.variants?.some(v => v.status === 'active' && v.stock > 0);
    if (!hasActiveVariants) return false;

    // Search filter
    if (!searchLower) return true;
    
    const matchesProductName = p.name.toLowerCase().includes(searchLower);
    const matchesVariant = p.variants?.some(v => 
      v.name.toLowerCase().includes(searchLower) || v.sku.toLowerCase().includes(searchLower)
    );
    
    return matchesProductName || matchesVariant;
  });

  const handleCardClick = (product) => {
    const available = product.variants?.filter(v => v.status === 'active' && v.stock > 0) || [];
    if (available.length === 1) {
      // Only one variant — skip modal and add directly
      onAddToCart(product, available[0]);
    } else {
      setSelectedProduct(product);
    }
  };

  return (
    <div className="pos-products-section">
      {/* Category Tabs */}
      <div className="category-scroll">
        {categoryNames.map(cat => (
          <button
            key={cat}
            className={`cat-tab ${activeCategory === cat ? 'active' : ''}`}
            onClick={() => onCategoryChange(cat)}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Product Cards */}
      <div className="product-grid">
        {filteredProducts.map(product => {
          const lowestPrice = Math.min(...(product.variants?.map(v => v.price) || [0]));
          const totalStock = (product.variants || [])
            .filter(v => v.status === 'active' && v.stock > 0)
            .reduce((s, v) => s + v.stock, 0);
          const variantCount = (product.variants || []).filter(v => v.status === 'active' && v.stock > 0).length;

          return (
            <motion.div
              key={product.id}
              className="pos-product-card"
              whileHover={{ y: -2, boxShadow: '0 8px 24px rgba(0,0,0,0.10)' }}
              whileTap={{ scale: 0.97 }}
              onClick={() => handleCardClick(product)}
            >
              {/* Product Image */}
              <div className="pos-card-image">
                {product.photo
                  ? <img src={product.photo} alt={product.name} />
                  : <div className="pos-card-placeholder">
                      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                        <rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/>
                      </svg>
                    </div>
                }
              </div>

              {/* Product Info */}
              <div className="product-card-info">
                <span className="p-name">{product.name}</span>
                <span className="v-name">{variantCount} variant{variantCount !== 1 ? 's' : ''}</span>
              </div>

              {/* Footer */}
              <div className="product-card-footer">
                <span className="p-price">from {formatCurrency(lowestPrice)}</span>
                <span className={`p-stock ${totalStock <= 5 ? 'low' : ''}`}>
                  {totalStock} left
                </span>
              </div>
            </motion.div>
          );
        })}
      </div>

      {/* Variant Picker Modal */}
      {selectedProduct && (
        <VariantModal
          product={selectedProduct}
          onClose={() => setSelectedProduct(null)}
          onSelect={onAddToCart}
        />
      )}
    </div>
  );
};

export default ProductGrid;
