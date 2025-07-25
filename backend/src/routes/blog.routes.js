const express = require('express');
const {
    getBlogs,
    getFeaturedBlogs,
    getBlog,
    getBlogCategories,
    createBlog,
    updateBlog,
    deleteBlog,
    likeBlog,
    getBlogStats
} = require('../controllers/blog.controller');

// Middleware pour l'authentification (si besoin pour les routes admin)
const { protect, authorize } = require('../middlewares/auth');

// Note: Validation middleware sera ajouté plus tard si nécessaire
// const { validate } = require('../middlewares/validation');

const router = express.Router();

// Routes publiques
router.get('/', getBlogs);                    // GET /api/blog - Tous les articles
router.get('/featured', getFeaturedBlogs);    // GET /api/blog/featured - Articles en vedette
router.get('/categories', getBlogCategories); // GET /api/blog/categories - Liste des catégories
router.get('/:slug', getBlog);                // GET /api/blog/:slug - Article par slug
router.post('/:id/like', likeBlog);           // POST /api/blog/:id/like - Liker un article

// Routes protégées (Admin seulement)
router.post('/', protect, authorize('admin', 'superadmin'), createBlog);        // POST /api/blog - Créer un article
router.put('/:id', protect, authorize('admin', 'superadmin'), updateBlog);      // PUT /api/blog/:id - Modifier un article
router.delete('/:id', protect, authorize('admin', 'superadmin'), deleteBlog);   // DELETE /api/blog/:id - Supprimer un article
router.get('/admin/stats', protect, authorize('admin', 'superadmin'), getBlogStats); // GET /api/blog/admin/stats - Statistiques

module.exports = router;
