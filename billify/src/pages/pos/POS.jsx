import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import ProductGrid from '../../components/pos/ProductGrid';
import CartPanel from '../../components/pos/CartPanel';
import { formatCurrency } from '../../utils/formatCurrency';

const POS = () => {
  const { products, categories, settings, addTransaction, showToast } = useDataContext();

  const [cart, setCart] = useState([]);
  const [activeCategory, setActiveCategory] = useState('All');
  const [discount, setDiscount] = useState('');
  const [flashOrderId, setFlashOrderId] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');

  const handleAddToCart = (product, variant) => {
    setCart(prev => {
      const cartItemId = `${product.id}-${variant.name}`;
      const existing = prev.find(item => item.cartItemId === cartItemId);

      if (existing) {
        if (existing.quantity >= variant.stock) {
          showToast('Out of stock!', 'error');
          return prev;
        }
        return prev.map(item =>
          item.cartItemId === cartItemId ? { ...item, quantity: item.quantity + 1 } : item
        );
      }

      return [...prev, {
        cartItemId,
        productId: product.id,
        name: product.name,
        variantName: variant.name,
        price: variant.price,
        stock: variant.stock,
        hsnCode: product.hsnCode || '',
        quantity: 1
      }];
    });

    // Trigger flash feedback
    setFlashOrderId(prev => prev + 1);
  };

  const handleUpdateQty = (cartItemId, delta) => {
    setCart(prev => prev.map(item => {
      if (item.cartItemId === cartItemId) {
        const newQty = item.quantity + delta;
        if (newQty <= 0) return item;
        if (newQty > item.stock) {
          showToast('Stock limit reached', 'warning');
          return item;
        }
        return { ...item, quantity: newQty };
      }
      return item;
    }));
  };

  const handleRemove = (cartItemId) => {
    setCart(prev => prev.filter(item => item.cartItemId !== cartItemId));
  };

  const handleCheckout = (paymentMethod) => {
    if (cart.length === 0) return;

    const subtotal = cart.reduce((acc, item) => acc + (item.price * item.quantity), 0);
    const taxRate = parseFloat(settings.taxPercentage || 0) / 100;
    const gstRate = parseFloat(settings.gstPercentage || 0) / 100;
    const discAmt = parseFloat(discount || 0);

    const tax = subtotal * taxRate;
    const gst = subtotal * gstRate;
    const total = subtotal + tax + gst - discAmt;

    const transaction = {
      type: 'Invoice',
      subtotal,
      tax,
      gst,
      discount: discAmt,
      total,
      paymentMethod,
      items: cart,
      itemsCount: cart.reduce((acc, i) => acc + i.quantity, 0)
    };

    addTransaction(transaction);
    setCart([]);
    setDiscount('');
  };

  return (
    <PageContainer>
      <motion.div
        className="pos-container"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.3 }}
      >
        <div style={{ display: 'flex', flexDirection: 'column', width: '100%', overflow: 'hidden' }}>
          {/* Search Bar */}
          <div style={{ padding: 'var(--spacing-4)', paddingBottom: 0, paddingRight: 'var(--spacing-2)' }}>
            <div style={{ position: 'relative', width: '100%' }}>
              <svg style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'var(--neutral-400)', width: '18px', height: '18px' }} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
              <input
                type="text"
                placeholder="Search products by name or SKU..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                style={{ width: '100%', padding: '0.625rem var(--spacing-4)', paddingLeft: '38px', borderRadius: 'var(--radius-lg)', border: '1px solid var(--neutral-200)', outline: 'none', fontSize: '0.9375rem', backgroundColor: 'white', transition: 'border-color 0.2s', boxShadow: 'var(--shadow-sm)' }}
                onFocus={(e) => e.target.style.borderColor = 'var(--primary-400)'}
                onBlur={(e) => e.target.style.borderColor = 'var(--neutral-200)'}
              />
            </div>
          </div>

          <ProductGrid
            products={products}
            categories={categories}
            activeCategory={activeCategory}
            onCategoryChange={setActiveCategory}
            onAddToCart={handleAddToCart}
            searchTerm={searchTerm}
          />
        </div>
        <div
          className={flashOrderId > 0 ? 'animate-flash' : ''}
          key={flashOrderId}
          style={{ height: '100%', display: 'flex', width: '100%' }}
        >
          <CartPanel
            cart={cart}
            onUpdateQty={handleUpdateQty}
            onRemove={handleRemove}
            onCheckout={handleCheckout}
            discount={discount}
            onDiscountChange={setDiscount}
            settings={settings}
          />
        </div>
      </motion.div>
    </PageContainer>
  );
};

export default POS;
