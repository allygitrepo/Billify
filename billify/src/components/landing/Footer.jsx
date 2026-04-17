import React from 'react';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container footer-container">
        <div className="footer-main">
          <div className="footer-info">
            <h2 className="footer-logo">Self Billing</h2>
            <p className="footer-description">
              Self Billing helps businesses manage billing, inventory, and transactions efficiently across multiple businesses.
            </p>
          </div>
          
          <div className="footer-links-group">
            <div className="footer-links">
              <h4 className="footer-heading">Company</h4>
              <ul>
                <li><a href="#">Home</a></li>
                <li><a href="#features">Features</a></li>
                <li><a href="#">What's New</a></li>
                <li><a href="#">Video Tutorials</a></li>
                <li><a href="#">FAQ</a></li>
                <li><a href="#">Contact Us</a></li>
              </ul>
            </div>
            
            <div className="footer-links">
              <h4 className="footer-heading">User Policy</h4>
              <ul>
                <li><a href="#">Privacy Policy</a></li>
                <li><a href="#">Refund Policy</a></li>
                <li><a href="#">Terms & Conditions</a></li>
              </ul>
            </div>
          </div>
          
          <div className="footer-contact">
            <h4 className="footer-heading">Contact Us</h4>
            <div className="contact-item">
              <p>205, Balaji Complex, 150 feet Ring-Road,</p>
              <p>Near Mahapujadham chowk, Rajkot - 360001</p>
            </div>
            <div className="contact-item">
              <p>+91 8866152292</p>
              <p>+91 9023960106</p>
            </div>
            <div className="contact-item">
              <p>contact@selfbilling.com</p>
              <p>support@selfbilling.com</p>
            </div>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p className="copyright">Copyright © 2026 Self Billing. All Rights Reserved.</p>
          <div className="social-links">
            <a href="#" className="social-icon">FB</a>
            <a href="#" className="social-icon">TW</a>
            <a href="#" className="social-icon">IG</a>
            <a href="#" className="social-icon">LI</a>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
