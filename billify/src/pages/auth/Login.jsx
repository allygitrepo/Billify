import React, { useState } from 'react';
import { useNavigate, NavLink } from 'react-router-dom';
import Input from '../../components/common/Input';
import Button from '../../components/common/Button';
import { validateEmail, validatePassword, validate } from '../../utils/validators';
import { useAuth } from '../../hooks/useAuth';
import Logo from '../../components/common/Logo';

const Login = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    rememberMe: false
  });
  const [errors, setErrors] = useState({});
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [touched, setTouched] = useState({});

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    
    // Clear error on change if it exists
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: null }));
    }
  };

  const handleBlur = (e) => {
    const { name } = e.target;
    setTouched(prev => ({ ...prev, [name]: true }));
    validateField(name, formData[name]);
  };

  const validateField = (name, value) => {
    let error = null;
    if (name === 'email') {
      error = validate(value, [(v) => !v ? 'Email is required' : null, validateEmail]);
    } else if (name === 'password') {
      error = validate(value, [(v) => !v ? 'Password is required' : null, validatePassword]);
    }
    
    setErrors(prev => ({ ...prev, [name]: error }));
    return error;
  };

  const { login } = useAuth();
  const [loginError, setLoginError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoginError('');
    
    // Validate all fields
    const emailError = validateField('email', formData.email);
    const passwordError = validateField('password', formData.password);
    
    if (emailError || passwordError) return;

    setIsLoading(true);
    
    try {
      // console.log('Login component: calling login hook');
      const result = await login(formData.email, formData.password);
      // console.log('Login component: login result:', result);
      setIsLoading(false);
      
      if (result.success) {
        // console.log('Login component: navigating to dashboard');
        navigate('/dashboard');
      } else {
        setLoginError(result.message);
      }
    } catch (error) {
      console.error('Login component: unexpected error:', error);
      setIsLoading(false);
      setLoginError('An unexpected error occurred. Please try again.');
    }
  };

  const isFormInvalid = !formData.email || !formData.password || !!errors.email || !!errors.password;

  return (
    <div className="auth-layout">
      <div className="auth-container">
        {/* Left Side - Branding */}
        <div className="auth-branding">
          <NavLink to="/" className="auth-logo-link">
            <Logo size="lg" />
          </NavLink>
          <div className="branding-content">
            <h1>Welcome to the future of <span className="text-primary">Business Management</span>.</h1>
            <p>Streamline your billing, track inventory, and grow your business with our all-in-one POS solution.</p>
          </div>
          <div className="branding-footer">
            <p>© 2026 Self Billing Inc.</p>
          </div>
        </div>

        {/* Right Side - Login Form */}
        <div className="auth-form-container">
          <div className="auth-card">
            <div className="auth-header">
              <h2>Login to your account</h2>
              <p>Enter your credentials to access your dashboard</p>
            </div>

            {loginError && (
              <div className="error-alert" style={{
                padding: 'var(--spacing-3)',
                backgroundColor: '#fee2e2',
                color: '#991b1b',
                borderRadius: '8px',
                marginBottom: 'var(--spacing-4)',
                fontSize: '0.875rem',
                textAlign: 'center',
                border: '1px solid #fecaca'
              }}>
                {loginError}
              </div>
            )}

            <form onSubmit={handleSubmit} className="login-form">
              <Input
                label="Email Address"
                name="email"
                type="email"
                placeholder="name@company.com"
                value={formData.email}
                onChange={handleChange}
                onBlur={handleBlur}
                error={touched.email && errors.email}
                required
              />

              <div className="password-field-wrapper">
                <Input
                  label="Password"
                  name="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  value={formData.password}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  error={touched.password && errors.password}
                  required
                />
                <button 
                  type="button" 
                  className="password-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                >
                  {showPassword ? 'Hide' : 'Show'}
                </button>
              </div>

              <div className="form-extras">
                <label className="remember-me">
                  <input
                    type="checkbox"
                    name="rememberMe"
                    checked={formData.rememberMe}
                    onChange={handleChange}
                  />
                  <span>Remember me</span>
                </label>
                <a href="#" className="forgot-password">Forgot password?</a>
              </div>

              <Button
                type="submit"
                variant="primary"
                className="w-full"
                isLoading={isLoading}
                disabled={isFormInvalid}
              >
                Login
              </Button>

              <div className="auth-footer">
                <p>Don't have an account? <NavLink to="/register">Register your business</NavLink></p>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
