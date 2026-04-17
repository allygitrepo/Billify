import React from 'react';
import { useDataContext } from '../../hooks/useDataContext';
import { Download, Printer, QrCode as QrIcon, Share2 } from 'lucide-react';
import Button from '../common/Button';

const BusinessQR = ({ size = 'medium' }) => {
  const { businessQr, settings, loading } = useDataContext();

  if (loading && !businessQr) {
    return (
      <div className="qr-card-loading">
        <div className="qr-skeleton-box animate-pulse"></div>
        <div className="qr-skeleton-text animate-pulse"></div>
      </div>
    );
  }

  if (!businessQr) {
    return (
      <div className="qr-card-empty">
        <QrIcon size={48} className="text-neutral-200 mb-2" />
        <p className="text-muted text-sm">QR profile not ready</p>
      </div>
    );
  }

  const handleDownload = () => {
    const link = document.createElement('a');
    link.href = businessQr.qr_image;
    link.download = `QR_${settings.businessName || 'Business'}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handlePrint = () => {
    const win = window.open('', '_blank');
    win.document.write(`
      <html>
        <head>
          <title>Print QR - ${settings.businessName}</title>
          <style>
            body { 
              display: flex; 
              flex-direction: column; 
              align-items: center; 
              justify-content: center; 
              height: 100vh; 
              font-family: 'Inter', sans-serif;
              background: #fdfdfd;
            }
            .container {
              padding: 40px;
              border: 2px solid #eee;
              border-radius: 24px;
              text-align: center;
              background: white;
            }
            img.qr { width: 350px; height: 350px; margin-bottom: 20px; }
            h1 { font-size: 28px; margin: 0; color: #111; }
            p { font-size: 18px; color: #666; margin-top: 8px; }
          </style>
        </head>
        <body>
          <div class="container">
            <img class="qr" src="${businessQr.qr_image}" />
            <h1>${settings.businessName}</h1>
            <p>${settings.phone || 'Business Profile'}</p>
          </div>
          <script>window.onload = () => { window.print(); window.close(); }</script>
        </body>
      </html>
    `);
    win.document.close();
  };

  return (
    <div className={`premium-qr-wrapper ${size}`}>
      <div className="qr-display-card">
        <div className="qr-inner-frame">
          <img src={businessQr.qr_image} alt="QR" className="main-qr-img" />
          
          <div className="qr-branding-center">
            {settings.photo ? (
              <img src={settings.photo} alt="Center Logo" className="qr-logo-overlay" />
            ) : (
              <div className="qr-initials-overlay">SB</div>
            )}
          </div>
        </div>
        
        <div className="qr-card-info">
          <span className="business-tag">Business Card</span>
          <h4 className="business-name-small">{settings.businessName}</h4>
        </div>
      </div>

      <div className="qr-action-row">
        <button className="qr-btn-action download" onClick={handleDownload} title="Download Image">
          <Download size={18} />
          <span>Save</span>
        </button>
        <button className="qr-btn-action print" onClick={handlePrint} title="Print QR">
          <Printer size={18} />
          <span>Print</span>
        </button>
      </div>
    </div>
  );
};

export default BusinessQR;
