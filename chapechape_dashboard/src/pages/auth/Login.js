import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { EyeIcon, EyeSlashIcon, EnvelopeIcon, LockClosedIcon } from '@heroicons/react/24/outline';
import { login } from '../../services/auth';
import { motion, AnimatePresence } from 'framer-motion';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const user = await login(email, password);

      if (rememberMe) {
        localStorage.setItem('remember_email', email);
      } else {
        localStorage.removeItem('remember_email');
      }

      // Redirection selon le rôle (case-insensitive pour éviter les mismatch 'SUPER_ADMIN' vs 'superadmin')
      const normalizedRole = String(user?.role || '').toLowerCase();
      if (normalizedRole === 'super_admin' || normalizedRole === 'superadmin') {
        navigate('/dashboard');
      } else {
        navigate('/');
      }
    } catch (err) {
      setError(err.message || 'Une erreur est survenue lors de la connexion');
    } finally {
      setLoading(false);
    }
  };

  // Récupérer l'email sauvegardé si "Se souvenir de moi" était coché
  useEffect(() => {
    const savedEmail = localStorage.getItem('remember_email');
    if (savedEmail) {
      setEmail(savedEmail);
      setRememberMe(true);
    }
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#E8EAF6] to-[#C5CAE9] flex items-center justify-center p-4 sm:p-6 lg:p-8">
      <div className="w-full max-w-md">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: "easeOut" }}
          className="bg-white rounded-3xl shadow-[0_20px_50px_rgba(26,35,126,0.15)] overflow-hidden"
        >
          {/* Header Section with Decorative Gradient */}
          <div className="relative h-32 bg-gradient-to-r from-[#1A237E] to-[#283593] flex items-center justify-center">
            <div className="absolute inset-0 opacity-20 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]"></div>
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.2, duration: 0.5 }}
              className="relative z-10 bg-white p-3 rounded-2xl shadow-lg"
            >
              <img
                src="/assets/logo.png"
                alt="ChapeChape Residence"
                className="h-12 w-auto"
              />
            </motion.div>
          </div>

          <div className="p-8 sm:p-10">
            <div className="text-center mb-8">
              <h2 className="text-2xl font-bold text-[#1A237E]">
                Bienvenue
              </h2>
              <p className="text-[#3949AB] mt-2 text-sm font-medium">
                Connectez-vous à votre espace administrateur
              </p>
            </div>

            <AnimatePresence mode="wait">
              {error && (
                <motion.div
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                  className="mb-6 overflow-hidden"
                >
                  <div className="bg-red-50 border-l-4 border-red-500 p-4 rounded-r-lg">
                    <div className="flex items-center">
                      <div className="flex-shrink-0">
                        <svg className="h-5 w-5 text-red-500" viewBox="0 0 20 20" fill="currentColor">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                        </svg>
                      </div>
                      <div className="ml-3">
                        <p className="text-sm text-red-700 font-medium">{error}</p>
                      </div>
                    </div>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label className="block text-sm font-semibold text-[#1A237E] mb-2 ml-1">
                  Email
                </label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <EnvelopeIcon className="h-5 w-5 text-[#3949AB] group-focus-within:text-[#1A237E] transition-colors" />
                  </div>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="block w-full pl-10 pr-3 py-3.5 rounded-xl bg-[#E8EAF6]/50 border border-[#C5CAE9] text-[#1A237E] placeholder-[#9FA8DA] focus:outline-none focus:ring-2 focus:ring-[#3949AB] focus:border-transparent focus:bg-white transition-all duration-200"
                    placeholder="admin@chapechape.com"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-semibold text-[#1A237E] mb-2 ml-1">
                  Mot de passe
                </label>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <LockClosedIcon className="h-5 w-5 text-[#3949AB] group-focus-within:text-[#1A237E] transition-colors" />
                  </div>
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="block w-full pl-10 pr-10 py-3.5 rounded-xl bg-[#E8EAF6]/50 border border-[#C5CAE9] text-[#1A237E] placeholder-[#9FA8DA] focus:outline-none focus:ring-2 focus:ring-[#3949AB] focus:border-transparent focus:bg-white transition-all duration-200"
                    placeholder="••••••••"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center"
                  >
                    {showPassword ? (
                      <EyeSlashIcon className="h-5 w-5 text-[#3949AB] hover:text-[#1A237E] transition-colors" />
                    ) : (
                      <EyeIcon className="h-5 w-5 text-[#3949AB] hover:text-[#1A237E] transition-colors" />
                    )}
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between pt-2">
                <div className="flex items-center">
                  <input
                    id="remember-me"
                    name="remember-me"
                    type="checkbox"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    className="h-4 w-4 text-[#1A237E] focus:ring-[#3949AB] border-[#C5CAE9] rounded cursor-pointer"
                  />
                  <label htmlFor="remember-me" className="ml-2 block text-sm text-[#3949AB] cursor-pointer select-none">
                    Se souvenir de moi
                  </label>
                </div>
                <button
                  type="button"
                  onClick={() => {/* TODO */ }}
                  className="text-sm font-semibold text-[#1A237E] hover:text-[#283593] hover:underline transition-all"
                >
                  Mot de passe oublié ?
                </button>
              </div>

              <motion.button
                type="submit"
                disabled={loading}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className="w-full flex justify-center py-3.5 px-4 border border-transparent rounded-xl shadow-md text-sm font-bold text-white bg-gradient-to-r from-[#1A237E] to-[#283593] hover:from-[#283593] hover:to-[#1A237E] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#3949AB] disabled:opacity-70 disabled:cursor-not-allowed transition-all duration-300"
              >
                {loading ? (
                  <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                ) : (
                  'Se connecter'
                )}
              </motion.button>
            </form>
          </div>
        </motion.div>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5, duration: 0.5 }}
          className="text-center text-[#5C6BC0] text-sm mt-8"
        >
          © {new Date().getFullYear()} ChapeChape Residence. Tous droits réservés.
        </motion.p>
      </div>
    </div>
  );
};

export default Login;
