import React, { useState, useEffect } from 'react';
import { API_URL, toggleHttps } from '../config';

/**
 * Composant pour basculer entre HTTP et HTTPS en mode développement
 * Utile pour tester l'API avec et sans SSL
 */
const HttpToggle = () => {
  const [isHttps, setIsHttps] = useState(false);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    // Lire la valeur de localStorage
    const savedValue = localStorage.getItem('use_https') === 'true';
    setIsHttps(savedValue);
  }, []);

  const handleToggle = () => {
    const newValue = toggleHttps();
    setIsHttps(newValue);
  };

  if (process.env.NODE_ENV === 'production') {
    return null; // Ne pas afficher en production
  }

  const getProtocol = () => {
    const url = new URL(API_URL);
    return url.protocol.replace(':', '');
  };

  return (
    <div 
      style={{
        position: 'fixed',
        bottom: 20,
        right: 20,
        backgroundColor: '#fff',
        boxShadow: '0 2px 8px rgba(0, 0, 0, 0.15)',
        borderRadius: 8,
        padding: expanded ? 16 : 8,
        zIndex: 1000,
        display: 'flex',
        flexDirection: 'column',
        cursor: 'pointer',
        transition: 'all 0.3s ease'
      }}
    >
      <div 
        onClick={() => setExpanded(!expanded)}
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: expanded ? 8 : 0
        }}
      >
        <span style={{ 
          fontWeight: 'bold', 
          fontSize: 14,
          marginRight: 10
        }}>
          {expanded ? 'Configuration API' : getProtocol().toUpperCase()}
        </span>
        <span style={{ fontSize: 18 }}>
          {expanded ? '▼' : '▲'}
        </span>
      </div>
      
      {expanded && (
        <>
          <div style={{ 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'space-between',
            marginBottom: 8
          }}>
            <span style={{ 
              color: isHttps ? 'green' : 'orange',
              fontWeight: 'bold',
              fontSize: 14
            }}>
              {isHttps ? 'HTTPS' : 'HTTP'}
            </span>
            <button
              onClick={handleToggle}
              style={{
                backgroundColor: isHttps ? 'green' : 'orange',
                color: 'white',
                border: 'none',
                borderRadius: 4,
                padding: '4px 8px',
                cursor: 'pointer'
              }}
            >
              Changer
            </button>
          </div>
          <div style={{ fontSize: 12, color: '#666' }}>
            {API_URL}
          </div>
          <div style={{ 
            fontSize: 11, 
            color: '#999', 
            marginTop: 4,
            fontStyle: 'italic'
          }}>
            Rafraîchissez la page après changement
          </div>
        </>
      )}
    </div>
  );
};

export default HttpToggle;
