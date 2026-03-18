import React from 'react';
import { formatCurrency } from '../../utils/formatCurrency';

const ProductGrid = ({ products, activeCategory, onCategoryChange, onAddToCart }) => {
  const categories = ['All', ...new Set(products.map(p => p.category))];

  const filteredProducts = activeCategory === 'All' 
    ? products 
    : products.filter(p => p.category === activeCategory);

  // Flatten products into variant cards
  const allVariants = filteredProducts
    .filter(p => p.status === 'active')
    .flatMap(product => 
      product.variants
        .filter(v => v.status === 'active')
        .map(variant => ({
          ...variant,
          productName: product.name,
          category: product.category,
          productId: product.id,
          product: product // Pass full product context
        }))
    );

  return (
    <div className="pos-products-section">
      <div className="category-scroll">
        {categories.map(cat => (
          <button
            key={cat}
            className={`cat-tab ${activeCategory === cat ? 'active' : ''}`}
            onClick={() => onCategoryChange(cat)}
          >
            {cat}
          </button>
        ))}
      </div>

      <div className="product-grid">
        {allVariants.map(variant => (
          <div 
            key={`${variant.productId}-${variant.name}`} 
            className="pos-product-card"
            onClick={() => onAddToCart(variant.product, variant)}
          >
            <div className="product-card-info">
              <span className="p-name">{variant.productName}</span>
              <span className="v-name">{variant.name}</span>
            </div>
            <div className="product-card-footer">
              <span className="p-price">{formatCurrency(variant.price)}</span>
              <span className={`p-stock ${variant.stock <= 5 ? 'low' : ''}`}>
                {variant.stock} left
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ProductGrid;
