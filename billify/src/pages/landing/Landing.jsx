import React, { useState, useEffect } from 'react';
import HeroSection from '../../components/landing/HeroSection';
import FeaturesSection from '../../components/landing/FeaturesSection';
import Footer from '../../components/landing/Footer';
import Logo from '../../components/common/Logo';
import { NavLink } from 'react-router-dom';

const Landing = () => {
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <div className="landing-page">
      <header className={`landing-header ${isScrolled ? 'scrolled' : ''}`}>
        <div className="container nav-container">
          <NavLink to="/" className="logo-link">
            <Logo />
          </NavLink>
          <nav className="nav-menu">
            <a href="#">Home</a>
            <a href="#features">Features</a>
            <a href="#">Pricing</a>
            <a href="#">Contact</a>
          </nav>
          <div className="nav-actions">
            <NavLink to="/login" className="btn btn-primary">Login</NavLink>
          </div>
        </div>
      </header>

      <main>
        <HeroSection />
        
        <FeaturesSection />

        <section className="how-it-works">
          <div className="container">
            <div className="section-header">
              <h2 className="section-title">How It Works</h2>
            </div>
            <div className="steps-grid">
              <div className="step-card">
                <div className="step-number">1</div>
                <h3>Add Products & Variants</h3>
                <p>Easily set up your product catalog with multiple variations and prices.</p>
              </div>
              <div className="step-card">
                <div className="step-number">2</div>
                <h3>Manage Inventory</h3>
                <p>Track stock levels automatically as you buy and sell products.</p>
              </div>
              <div className="step-card">
                <div className="step-number">3</div>
                <h3>Start Billing</h3>
                <p>Create professional invoices and manage transactions effortlessly.</p>
              </div>
            </div>
          </div>
        </section>

        <section className="cta-section">
          <div className="container cta-container">
            <h2>Start Managing Your Business with Billify</h2>
            <NavLink to="/login" className="btn btn-primary btn-lg">Get Started Now</NavLink>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  );
};

export default Landing;
