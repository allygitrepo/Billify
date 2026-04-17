import React, { useState, useEffect, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { useDataContext } from '../../hooks/useDataContext';
import { customerService } from '../../services/customer.service';
import { paymentService } from '../../services/payment.service';
import { invoiceService } from '../../services/invoice.service';
import PageContainer from '../../components/layout/PageContainer';
import Loader from '../../components/common/Loader';
import Table from '../../components/common/Table';
import Button from '../../components/common/Button';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import CustomerBalanceCard from './components/CustomerBalanceCard';
import AddTransactionModal from './components/AddTransactionModal';
import { formatCurrency } from '../../utils/formatCurrency';
import { formatDate } from '../../utils/formatDate';

const CustomerDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { showToast, deleteCustomer, businessId } = useDataContext();

  const [ledgerData, setLedgerData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('ledger');
  
  // Modal states
  const [isTxModalOpen, setIsTxModalOpen] = useState(false);
  const [txType, setTxType] = useState('credit'); // credit (gave) or debit (got)
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [itemToDelete, setItemToDelete] = useState(null);

  const fetchLedger = useCallback(async () => {
    try {
      setLoading(true);
      // Fetch both Ledger and Business Invoices to cross-reference (Matching User Request)
      let invoices = [];
      if (businessId) {
        invoices = await invoiceService.getInvoices(businessId);
      }
      
      const ledgerRes = await customerService.getCustomerLedger(id);

      const rawData = ledgerRes.data;
      
      // Data Cleaning & Merging (Syncing actual Invoice payment data into fragments)
      if (rawData.ledger && invoices) {
        rawData.ledger = rawData.ledger.map(tx => {
          const isInvoiceRow = tx.referenceInvoiceId || tx.note?.includes('INV #');
          if (isInvoiceRow) {
            // Find actual invoice by ID or referenceID
            const actualInv = invoices.find(inv => 
              inv.id === tx.referenceInvoiceId || 
              (tx.note && tx.note.includes(inv.invoice_number))
            );
            
            if (actualInv) {
              return {
                ...tx,
                amount: parseFloat(actualInv.final_amount), // Use Actual Total (Given)
                paid_amount: parseFloat(actualInv.paid_amount || 0) // Use Actual Payment (Got)
              };
            }
          }
          return tx;
        });
      }

      setLedgerData(rawData);
    } catch (error) {
      showToast(error.message || 'Failed to fetch ledger', 'error');
    } finally {
      setLoading(false);
    }
  }, [id, showToast, businessId]);

  useEffect(() => {
    fetchLedger();
  }, [fetchLedger]);

  const handleAddTransaction = async (formData) => {
    try {
      const payload = {
        ...formData,
        customer_id: parseInt(id)
      };

      if (txType === 'credit') {
        await paymentService.givePayment(payload);
      } else {
        await paymentService.receivePayment(payload);
      }

      showToast('Transaction recorded successfully');
      setIsTxModalOpen(false);
      fetchLedger();
    } catch (error) {
      showToast(error.message || 'Failed to record transaction', 'error');
    }
  };

  const handleDeleteTransaction = async () => {
    if (!itemToDelete) return;
    try {
      await paymentService.deletePayment(itemToDelete);
      showToast('Transaction reverted successfully');
      fetchLedger();
    } catch (error) {
      showToast(error.message || 'Failed to delete transaction', 'error');
    } finally {
      setIsDeleteModalOpen(false);
      setItemToDelete(null);
    }
  };

  const openTxModal = (type) => {
    setTxType(type);
    setIsTxModalOpen(true);
  };

  // Recalculate summary and enrich transactions to show "In and Out" flow (Matching user request)
  // Moved before early returns to satisfy Rules of Hooks
  const { summary, enrichedTransactions } = React.useMemo(() => {
    if (!ledgerData) return { summary: null, enrichedTransactions: [] };
    
    const { customer, summary: backendSummary, ledger: transactions = [] } = ledgerData;
    
    // 1. Generate Enriched Transactions (Splitting Invoices with upfront pay into two rows)
    const enriched = [];
    transactions.forEach((tx) => {
      // Keep original transaction
      enriched.push(tx);

      // If it's an Invoice (credit) and has an upfront paid_amount, 
      // create a synthetic "Payment Received" row for visibility
      const paidAmt = parseFloat(tx.paid_amount || 0);
      if (tx.type === 'credit' && paidAmt > 0) {
        enriched.push({
          ...tx,
          id: `paid_${tx.id}`,
          type: 'debit',
          amount: paidAmt,
          note: tx.isSynthetic ? tx.note : `Upfront Payment (INV #${tx.referenceInvoiceId || tx.id})`,
          isSynthetic: true
        });
      }
    });

    // 2. Sum debit entries (Total Got)
    const totalDebit = enriched
      .filter(t => t.type === 'debit')
      .reduce((sum, t) => sum + (parseFloat(t.amount) || 0), 0);

    const totalCredit = backendSummary?.totalCredit || 0;
    
    // Net Balance = (Given + Opening) - Got
    const openingBalance = parseFloat(customer?.opening_balance || 0);
    const netBalance = (parseFloat(totalCredit) + openingBalance) - totalDebit;

    return {
      summary: {
        ...backendSummary,
        totalDebit,
        remainingBalance: netBalance
      },
      enrichedTransactions: enriched
    };
  }, [ledgerData]);

  if (loading && !ledgerData) return <Loader fullPage />;
  if (!ledgerData) return <PageContainer title="Error">Customer not found.</PageContainer>;

  const { customer } = ledgerData;

  const columns = [
    {
      key: 'createdAt',
      label: 'Date',
      render: (val) => <span style={{ fontSize: '0.8125rem', color: 'var(--neutral-500)' }}>{formatDate(val)}</span>
    },
    {
      key: 'type',
      label: 'Type',
      render: (type, row) => {
        const isCredit = type === 'credit';
        const isInvoice = row.referenceInvoiceId || (row.note?.includes('INV #'));
        const isUpfront = row.isSynthetic;
        
        return (
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--spacing-2)' }}>
            <div style={{ 
              width: 24, height: 24, borderRadius: '50%', 
              backgroundColor: isUpfront ? 'rgba(16, 185, 129, 0.15)' : isCredit ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: isUpfront ? 'var(--primary-700)' : isCredit ? 'var(--danger-500)' : 'var(--primary-600)'
            }}>
              {isInvoice && !isUpfront ? '📄' : isUpfront ? '💰' : isCredit ? '↑' : '↓'}
            </div>
            <span style={{ fontSize: '0.875rem', fontWeight: '500' }}>
              {isUpfront ? 'Upfront Payment' : isInvoice ? 'Invoice' : isCredit ? 'Credit Entry' : 'Payment Received'}
            </span>
          </div>
        )
      }
    },
    {
      key: 'note',
      label: 'Notes / Remarks',
      render: (note) => <span style={{ fontSize: '0.875rem', color: 'var(--neutral-600)' }}>{note || '-'}</span>
    },
    {
      key: 'amount',
      label: 'Amount',
      render: (val, row) => (
        <span style={{ 
          fontWeight: '700', 
          color: row.type === 'credit' ? 'var(--danger-600)' : 'var(--primary-600)' 
        }}>
          {formatCurrency(val)}
        </span>
      )
    },
    {
      key: 'actions',
      label: '',
      render: (_, row) => !row.referenceInvoiceId && !row.isSynthetic && (
        <button 
          className="btn-icon-danger" 
          onClick={() => { setItemToDelete(row.id); setIsDeleteModalOpen(true); }}
          title="Delete Transaction"
        >
          🗑
        </button>
      )
    }
  ];

  return (
    <PageContainer
      title={customer.name}
      subtitle={customer.phone_number}
      backButton={() => navigate('/customers')}
      actions={
        <div style={{ display: 'flex', gap: 'var(--spacing-3)' }}>
          <Button variant="secondary" onClick={() => navigate(`/customers?edit=${id}`)}>✏️ Edit</Button>
        </div>
      }
    >
      <div className="animate-fade-in" style={{ paddingBottom: '100px' }}>
        <CustomerBalanceCard summary={summary} />

        <div className="tabs-container mb-6">
          <button 
            className={`tab-item ${activeTab === 'ledger' ? 'active' : ''}`}
            onClick={() => setActiveTab('ledger')}
          >
            📜 Ledger (Khata)
          </button>
          <button 
            className={`tab-item ${activeTab === 'info' ? 'active' : ''}`}
            onClick={() => setActiveTab('info')}
          >
            ℹ️ Basic Info
          </button>
        </div>

        {activeTab === 'ledger' ? (
          <div className="card">
            <Table columns={columns} data={enrichedTransactions} />
          </div>
        ) : (
          <div className="card" style={{ padding: 'var(--spacing-6)' }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 'var(--spacing-6)' }}>
              <div>
                <p style={{ fontSize: '0.75rem', color: 'var(--neutral-400)', textTransform: 'uppercase', marginBottom: '4px' }}>Customer Name</p>
                <p style={{ fontWeight: '600' }}>{customer.name}</p>
              </div>
              <div>
                <p style={{ fontSize: '0.75rem', color: 'var(--neutral-400)', textTransform: 'uppercase', marginBottom: '4px' }}>Phone Number</p>
                <p style={{ fontWeight: '600' }}>{customer.phone_number}</p>
              </div>
              <div>
                <p style={{ fontSize: '0.75rem', color: 'var(--neutral-400)', textTransform: 'uppercase', marginBottom: '4px' }}>City / Address</p>
                <p style={{ fontWeight: '600' }}>{customer.city || 'Not specified'}</p>
              </div>
              <div>
                <p style={{ fontSize: '0.75rem', color: 'var(--neutral-400)', textTransform: 'uppercase', marginBottom: '4px' }}>Opening Balance</p>
                <p style={{ fontWeight: '600' }}>{formatCurrency(customer.opening_balance)}</p>
              </div>
              <div>
                <p style={{ fontSize: '0.75rem', color: 'var(--neutral-400)', textTransform: 'uppercase', marginBottom: '4px' }}>Member Since</p>
                <p style={{ fontWeight: '600' }}>{formatDate(customer.createdAt)}</p>
              </div>
            </div>
          </div>
        )}

        {/* Floating Actions Footer */}
        <div style={{
          position: 'fixed',
          bottom: 0,
          left: '256px', // Sidebar width
          right: 0,
          padding: 'var(--spacing-4) var(--spacing-8)',
          backgroundColor: 'white',
          borderTop: '1px solid var(--neutral-200)',
          display: 'flex',
          gap: 'var(--spacing-4)',
          boxShadow: '0 -4px 12px rgba(0,0,0,0.05)',
          zIndex: 40
        }} className="customer-detail-actions">
          <Button 
            variant="danger" 
            block 
            style={{ padding: 'var(--spacing-4)', height: 'auto', backgroundColor: 'var(--danger-600)' }}
            onClick={() => openTxModal('credit')}
          >
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <span style={{ fontSize: '0.75rem', opacity: 0.9 }}>YOU GAVE</span>
              <span style={{ fontWeight: '800', fontSize: '1.1rem' }}>₹ GIVE CREDIT</span>
            </div>
          </Button>
          <Button 
            variant="success" 
            block 
            style={{ padding: 'var(--spacing-4)', height: 'auto', backgroundColor: 'var(--primary-600)' }}
            onClick={() => openTxModal('debit')}
          >
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <span style={{ fontSize: '0.75rem', opacity: 0.9 }}>YOU GOT</span>
              <span style={{ fontWeight: '800', fontSize: '1.1rem' }}>₹ GET PAYMENT</span>
            </div>
          </Button>
        </div>
      </div>

      <AddTransactionModal 
        isOpen={isTxModalOpen}
        onClose={() => setIsTxModalOpen(false)}
        onSubmit={handleAddTransaction}
        type={txType}
        customerName={customer.name}
      />

      <ConfirmDialog
        isOpen={isDeleteModalOpen}
        onClose={() => setIsDeleteModalOpen(false)}
        onConfirm={handleDeleteTransaction}
        title="Delete Transaction"
        message="Are you sure you want to delete this transaction? The customer's balance will be reverted."
      />

      <style>{`
        .tabs-container {
          display: flex;
          gap: var(--spacing-2);
          border-bottom: 1px solid var(--neutral-100);
        }
        .tab-item {
          padding: var(--spacing-3) var(--spacing-6);
          border: none;
          background: none;
          font-size: 0.875rem;
          font-weight: 600;
          color: var(--neutral-500);
          cursor: pointer;
          position: relative;
          transition: all 0.2s;
        }
        .tab-item:hover { color: var(--primary-600); }
        .tab-item.active { color: var(--primary-600); }
        .tab-item.active::after {
          content: '';
          position: absolute;
          bottom: -1px;
          left: 0;
          right: 0;
          height: 2px;
          backgroundColor: var(--primary-600);
        }
        @media (max-width: 1024px) {
          .customer-detail-actions { left: 0 !important; }
        }
      `}</style>
    </PageContainer>
  );
};

export default CustomerDetail;
