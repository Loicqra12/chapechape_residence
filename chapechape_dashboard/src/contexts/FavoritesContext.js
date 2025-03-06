import React, { createContext, useContext, useState, useEffect } from 'react';
import toast from 'react-hot-toast';

const FavoritesContext = createContext();

export const FavoritesProvider = ({ children }) => {
  const [favorites, setFavorites] = useState([]);

  useEffect(() => {
    const storedFavorites = localStorage.getItem('favorites');
    if (storedFavorites) {
      setFavorites(JSON.parse(storedFavorites));
    }
  }, []);

  const saveFavorites = (newFavorites) => {
    localStorage.setItem('favorites', JSON.stringify(newFavorites));
    setFavorites(newFavorites);
  };

  const addFavorite = (item) => {
    if (!favorites.find(f => f.id === item.id)) {
      const newFavorites = [...favorites, { ...item, addedAt: new Date() }];
      saveFavorites(newFavorites);
      toast.success('Ajouté aux favoris');
    }
  };

  const removeFavorite = (itemId) => {
    const newFavorites = favorites.filter(f => f.id !== itemId);
    saveFavorites(newFavorites);
    toast.success('Retiré des favoris');
  };

  const isFavorite = (itemId) => {
    return favorites.some(f => f.id === itemId);
  };

  const getFavoritesByType = (type) => {
    return favorites.filter(f => f.type === type);
  };

  return (
    <FavoritesContext.Provider value={{
      favorites,
      addFavorite,
      removeFavorite,
      isFavorite,
      getFavoritesByType
    }}>
      {children}
    </FavoritesContext.Provider>
  );
};

export const useFavorites = () => useContext(FavoritesContext);
