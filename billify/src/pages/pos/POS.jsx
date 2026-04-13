import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import PageContainer from '../../components/layout/PageContainer';
import ProductGrid from '../../components/pos/ProductGrid';
import CartPanel from '../../components/pos/CartPanel';
import InvoiceModal from '../../components/pos/InvoiceModal';
import WeightInputModal from '../../components/pos/WeightInputModal';
import CustomerSelectorModal from '../../components/pos/CustomerSelectorModal';
import { formatCurrency } from '../../utils/formatCurrency';
import { printInvoice } from '../../utils/printService';

const POS = () => {
  const { products, categories, settings, user, addTransaction, showToast } = useDataContext();

  const [cart, setCart] = useState([]);
  const [activeCategory, setActiveCategory] = useState('All');
  const [discount, setDiscount] = useState('');
  const [flashOrderId, setFlashOrderId] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Invoice Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [newInvoiceData, setNewInvoiceData] = useState(null);

  // Flow States
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [paymentMode, setPaymentMode] = useState('CASH'); // CASH, KHATA, SPLIT
  const [paidAmount, setPaidAmount] = useState('');
  
  // Flow Modals
  const [weightModalData, setWeightModalData] = useState(null);
  const [isCustomerModalOpen, setIsCustomerModalOpen] = useState(false);
  const [pendingCheckoutData, setPendingCheckoutData] = useState(null);



  const { customers = [] } = useDataContext();

  const handleAddToCart = (product, variant, manualQty = null) => {
    if (product.is_weighted && manualQty === null) {
      setWeightModalData({ product, variant });
      return;
    }

    setCart(prev => {
      const cartItemId = `${product.id}-${variant.name}`;
      const existing = prev.find(item => item.cartItemId === cartItemId);
      const qtyToAdd = manualQty !== null ? manualQty : 1;

      if (existing) {
        const variantStock = variant.current_stock ?? variant.stock ?? 0;
        if (existing.quantity + qtyToAdd > variantStock) {
          showToast('Insufficient stock!', 'error');
          return prev;
        }
        return prev.map(item =>
          item.cartItemId === cartItemId ? { ...item, quantity: item.quantity + qtyToAdd } : item
        );
      }

      return [...prev, {
        cartItemId,
        productId: product.id,
        name: product.name,
        variantName: variant.name,
        price: variant.price,
        stock: variant.current_stock ?? variant.stock ?? 0,
        hsnCode: product.hsnCode || '',
        quantity: qtyToAdd
      }];
    });

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

  const handleCheckoutTrigger = async (paymentMethod) => {
    if (cart.length === 0) return;

    const subtotal = cart.reduce((acc, item) => acc + (item.price * item.quantity), 0);
    const taxRate = parseFloat(settings.taxPercentage || 0) / 100;
    const gstRate = parseFloat(settings.gstPercentage || 0) / 100;
    const discAmt = parseFloat(discount || 0);

    const tax = subtotal * taxRate;
    const gst = subtotal * gstRate;
    const total = subtotal + tax + gst - discAmt;

    // Validation for payment modes
    if (paymentMode === 'KHATA' && !selectedCustomer) {
      showToast('Please select a customer for Khata (Credit)', 'warning');
      return;
    }

    const finalPaid = paymentMode === 'CASH' ? total : (parseFloat(paidAmount) || 0);

    const transaction = {
      type: 'Invoice',
      subtotal,
      tax,
      gst,
      discount: discAmt,
      total,
      paymentMode,
      paidAmount: finalPaid,
      customer_id: selectedCustomer?.id,
      customer_type: selectedCustomer ? 'REGULAR' : 'WALKIN',
      customerName: selectedCustomer?.name || 'Walk-in Customer',
      customerPhone: selectedCustomer?.phone || '',
      items: cart,
      itemsCount: cart.reduce((acc, i) => acc + i.quantity, 0)
    };

    try {
      const result = await addTransaction(transaction);
      if (result) {
        setNewInvoiceData(result);
        setIsModalOpen(true);
        setCart([]);
        setDiscount('');
        setSelectedCustomer(null);
        setPaymentMode('CASH');
        setPaidAmount('');
      }
    } catch (err) {
      // Handled in context
    }
  };



  const handlePrint = (transaction) => {
    printInvoice(transaction, settings);
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
            onCheckout={handleCheckoutTrigger}
            discount={discount}
            onDiscountChange={setDiscount}
            settings={settings}
            customers={customers}
            selectedCustomer={selectedCustomer}
            onSelectCustomer={setSelectedCustomer}
            paymentMode={paymentMode}
            onPaymentModeChange={setPaymentMode}
            paidAmount={paidAmount}
            onPaidAmountChange={setPaidAmount}
          />
        </div>
      </motion.div>

      {/* Weight Modal */}
      {weightModalData && (
        <WeightInputModal
          product={weightModalData.product}
          variant={weightModalData.variant}
          onClose={() => setWeightModalData(null)}
          onAdd={handleAddToCart}
        />
      )}

      {/* Invoice Modal to show after checkout */}


      <InvoiceModal 
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        transaction={newInvoiceData}
        settings={settings}
        user={user}
        onPrint={handlePrint}
      />
    </PageContainer>
  );
};

export default POS;
