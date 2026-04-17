import React, { useState, useEffect } from 'react';
import { useAuth } from '../../hooks/useAuth';
import { tableService } from '../../services/table.service';
import PageContainer from '../../components/layout/PageContainer';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';
import ConfirmModal from '../../components/common/ConfirmModal';
import { Plus, Trash2, Download, Printer, Users, CheckSquare, Square, Trash } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const TableManagement = () => {
  const { user } = useAuth();
  const businessId = user?.businessId;
  
  const [tables, setTables] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isAdding, setIsAdding] = useState(false);
  const [newTable, setNewTable] = useState({ count: '', capacity: '', prefix: 'Table' });
  
  const [selectedIds, setSelectedIds] = useState([]);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null); // 'single' | 'bulk'
  const [targetId, setTargetId] = useState(null);

  useEffect(() => {
    if (businessId) fetchTables();
  }, [businessId]);

  const fetchTables = async () => {
    try {
      setLoading(true);
      const data = await tableService.getTables(businessId);
      setTables(data);
      setSelectedIds([]);
    } catch (error) {
      console.error('Failed to fetch tables');
    } finally {
      setLoading(false);
    }
  };

  const handleToggleSelect = (id) => {
    setSelectedIds(prev => 
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  const handleSelectAll = () => {
    if (selectedIds.length === tables.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(tables.map(t => t.id));
    }
  };

  const openDeleteModal = (id = null) => {
    if (id) {
      setDeleteTarget('single');
      setTargetId(id);
    } else {
      setDeleteTarget('bulk');
    }
    setShowDeleteModal(true);
  };

  const handleConfirmDelete = async () => {
    try {
      if (deleteTarget === 'single') {
        await tableService.deleteTable(targetId);
      } else {
        await tableService.deleteTablesBulk(selectedIds);
      }
      fetchTables();
      setShowDeleteModal(false);
    } catch (error) {
      console.error('Failed to delete');
    }
  };

  const handleDownloadQR = (qrImage, tableNumber) => {
    const link = document.createElement('a');
    link.href = qrImage;
    link.download = `QR_${tableNumber}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <PageContainer title="Restaurant Tables">
      <div className="table-page-header mb-4" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <p className="text-muted">Generate multiple QR codes for your restaurant tables instantly.</p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          {tables.length > 0 && (
            <Button 
                variant="secondary"
                icon={selectedIds.length === tables.length ? <CheckSquare size={18} /> : <Square size={18} />}
                onClick={handleSelectAll}
            >
                {selectedIds.length === tables.length ? 'Deselect All' : 'Select All'}
            </Button>
          )}
          <Button 
            variant={isAdding ? 'secondary' : 'primary'}
            icon={<Plus size={18} />} 
            onClick={() => setIsAdding(!isAdding)}
          >
            {isAdding ? 'Cancel' : 'Bulk Generate'}
          </Button>
        </div>
      </div>

      <AnimatePresence>
        {selectedIds.length > 0 && (
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            className="bulk-action-bar"
          >
            <div className="selected-count-info">
              <CheckSquare size={20} className="text-danger-500" />
              <span>{selectedIds.length} Tables Selected</span>
            </div>
            <button 
              className="bulk-delete-btn" 
              onClick={() => openDeleteModal()}
            >
              <Trash size={18} />
              Delete Selected
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {isAdding && (
          <motion.div 
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="mb-8"
          >
            {/* ... form content here ... */}
            <div className="card p-6 border-primary" style={{ border: '2px dashed var(--primary-200)', background: 'var(--primary-50)' }}>
              <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                <Plus size={20} className="text-primary-600" />
                Bulk Table Generator
              </h3>
              <form onSubmit={async (e) => {
                  e.preventDefault();
                  if (!newTable.count) return;
                  try {
                    await tableService.createTable({...newTable, business_id: businessId});
                    setNewTable({ count: '', capacity: '', prefix: 'Table' });
                    setIsAdding(false);
                    fetchTables();
                  } catch (err) {}
              }} className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <Input 
                  label="Total Tables" 
                  type="number"
                  placeholder="e.g. 10"
                  value={newTable.count}
                  onChange={(e) => setNewTable({ ...newTable, count: e.target.value })}
                  required
                />
                <Input 
                  label="Seats per Table" 
                  type="number"
                  placeholder="e.g. 4"
                  value={newTable.capacity}
                  onChange={(e) => setNewTable({ ...newTable, capacity: e.target.value })}
                />
                <Input 
                  label="Label Prefix" 
                  type="text"
                  placeholder="e.g. Table"
                  value={newTable.prefix}
                  onChange={(e) => setNewTable({ ...newTable, prefix: e.target.value })}
                />
                <div style={{ display: 'flex', alignItems: 'flex-end', paddingBottom: '2px' }}>
                   <Button variant="primary" type="submit" style={{ width: '100%', height: '44px' }}>Generate All QR Codes</Button>
                </div>
              </form>
              <p className="text-xs text-muted mt-4">
                * This will create table records from 1 to {newTable.count || 'X'} and generate unique QR codes for each.
              </p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {loading ? (
        <div className="flex justify-center p-20" style={{ display: 'flex', justifyContent: 'center', padding: '100px' }}>
          <div className="spinner"></div>
        </div>
      ) : (
        <div className="tables-grid-container">
          {tables.length === 0 ? (
            <div className="card text-center p-20" style={{ gridColumn: '1 / -1', border: '2px dashed var(--neutral-200)', background: 'var(--neutral-50)', padding: '60px' }}>
              <Users size={48} className="text-neutral-300 mx-auto mb-4" />
              <h3 className="text-lg font-semibold">No tables added yet</h3>
              <p className="text-muted">Generate tables to see them here.</p>
            </div>
          ) : (
            tables.map(table => (
              <motion.div 
                key={table.id}
                layout
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                className={`table-qr-card ${selectedIds.includes(table.id) ? 'selected' : ''}`}
                onClick={() => handleToggleSelect(table.id)}
                style={{ cursor: 'pointer', position: 'relative' }}
              >
                {selectedIds.includes(table.id) && (
                  <div className="selection-indicator">
                    <CheckSquare size={18} />
                  </div>
                )}
                <div className="table-card-header">
                  <div className="table-id-info">
                    <h4>{table.table_number}</h4>
                    <span className="table-capacity">
                      <Users size={12} /> {table.capacity || 0} Seats
                    </span>
                  </div>
                  <button 
                    className="delete-table-btn"
                    onClick={(e) => {
                      e.stopPropagation();
                      openDeleteModal(table.id);
                    }}
                    title="Delete Table"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
                {/* ... existing card content ... */}

                <div className="table-qr-box">
                  {table.qr_image ? (
                    <img src={table.qr_image} alt="QR" />
                  ) : (
                    <div className="animate-pulse bg-neutral-100 w-full h-full rounded-lg" style={{ width: '100%', height: '100%' }}></div>
                  )}
                </div>

                <div className="table-card-actions">
                  <button 
                    className="table-action-btn"
                    onClick={() => handleDownloadQR(table.qr_image, table.table_number)}
                  >
                    <Download size={14} /> <span>Save</span>
                  </button>
                  <button 
                    className="table-action-btn"
                    onClick={() => window.print()}
                  >
                    <Printer size={14} /> <span>Print</span>
                  </button>
                </div>
              </motion.div>
            ))
          )}
        </div>
      )}

      <ConfirmModal 
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        onConfirm={handleConfirmDelete}
        title={deleteTarget === 'single' ? "Delete Table" : "Delete Selected Tables"}
        message={deleteTarget === 'single' 
            ? "Are you sure you want to delete this table? This will also remove its QR code."
            : `Are you sure you want to delete these ${selectedIds.length} tables and their QR codes?`}
        confirmText="Yes, Delete"
        cancelText="Cancel"
      />
    </PageContainer>
  );
};

export default TableManagement;
