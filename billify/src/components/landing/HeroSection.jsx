import { NavLink } from 'react-router-dom';

const HeroSection = () => {
  return (
    <section className="hero-section">
      <div className="container hero-container">
        <div className="hero-content">
          <h1 className="hero-title">
            Smart Billing & <span className="text-primary">Inventory Management</span> System
          </h1>
          <p className="hero-subtitle">
            Manage products, inventory, and billing efficiently with a fast and scalable POS system.
          </p>
          <div className="hero-buttons">
            <NavLink to="/login" className="btn btn-primary btn-lg">Get Started</NavLink>
            <button className="btn btn-secondary btn-lg">View Demo</button>
          </div>
        </div>
        <div className="hero-image">
          <div className="hero-image-container">
            <img src="/landingpage_photo.png" alt="Self Billing Dashboard Preview" className="hero-photo" />
          </div>
        </div>
      </div>
    </section>
  );
};

export default HeroSection;
