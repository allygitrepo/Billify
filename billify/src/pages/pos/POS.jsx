import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import ProductGrid from '../../components/pos/ProductGrid';
import CartPanel from '../../components/pos/CartPanel';
import { formatCurrency } from '../../utils/formatCurrency';

const POS = () => {
  const { products, settings, addTransaction } = useDataContext();

  const [cart, setCart] = useState([]);
  const [activeCategory, setActiveCategory] = useState('All');
  const [discount, setDiscount] = useState('');
  const [flashOrderId, setFlashOrderId] = useState(0);

  const handleAddToCart = (product, variant) => {
    setCart(prev => {
      const cartItemId = `${product.id}-${variant.name}`;
      const existing = prev.find(item => item.cartItemId === cartItemId);
      
      if (existing) {
        if (existing.quantity >= variant.stock) {
          alert('Out of stock!');
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
          alert('Stock limit reached');
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
    alert('Bill Generated Successfully!');
    setCart([]);
    setDiscount('');
  };

  return (
    <PageContainer title="POS Billing">
      <motion.div 
        className="pos-container"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.3 }}
      >
        <ProductGrid 
          products={products}
          activeCategory={activeCategory}
          onCategoryChange={setActiveCategory}
          onAddToCart={handleAddToCart}
        />
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
