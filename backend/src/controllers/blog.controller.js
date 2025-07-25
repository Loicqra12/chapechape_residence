const Blog = require('../models/blog.model');
const asyncHandler = require('../middlewares/async');

// @desc    Get all published blog posts
// @route   GET /api/blog
// @access  Public
exports.getBlogs = asyncHandler(async (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const category = req.query.category;
    const featured = req.query.featured;
    const search = req.query.search;

    // Build query
    let query = { status: 'published' };
    
    if (category) {
        query.category = category;
    }
    
    if (featured === 'true') {
        query.featured = true;
    }

    let blogs;
    
    if (search) {
        // Use text search
        blogs = await Blog.search(search)
            .skip((page - 1) * limit)
            .limit(limit)
            .select('-content'); // Exclude full content for list view
    } else {
        blogs = await Blog.find(query)
            .sort({ publishedAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit)
            .select('-content'); // Exclude full content for list view
    }

    // Get total count for pagination
    const total = await Blog.countDocuments(query);
    const totalPages = Math.ceil(total / limit);

    res.status(200).json({
        success: true,
        count: blogs.length,
        pagination: {
            page,
            limit,
            total,
            totalPages,
            hasNext: page < totalPages,
            hasPrev: page > 1
        },
        data: blogs
    });
});

// @desc    Get featured blog posts for homepage
// @route   GET /api/blog/featured
// @access  Public
exports.getFeaturedBlogs = asyncHandler(async (req, res) => {
    const limit = parseInt(req.query.limit) || 3;
    
    const blogs = await Blog.getFeatured(limit)
        .select('-content'); // Exclude full content
    
    res.status(200).json({
        success: true,
        count: blogs.length,
        data: blogs
    });
});

// @desc    Get single blog post
// @route   GET /api/blog/:slug
// @access  Public
exports.getBlog = asyncHandler(async (req, res) => {
    const blog = await Blog.findOne({ 
        slug: req.params.slug, 
        status: 'published' 
    });

    if (!blog) {
        return res.status(404).json({
            success: false,
            error: 'Article non trouvé'
        });
    }

    // Increment views
    await blog.incrementViews();

    res.status(200).json({
        success: true,
        data: blog
    });
});

// @desc    Get blog categories
// @route   GET /api/blog/categories
// @access  Public
exports.getBlogCategories = asyncHandler(async (req, res) => {
    const categories = await Blog.distinct('category', { status: 'published' });
    
    // Get count for each category
    const categoriesWithCount = await Promise.all(
        categories.map(async (category) => {
            const count = await Blog.countDocuments({ 
                category, 
                status: 'published' 
            });
            return { name: category, count };
        })
    );

    res.status(200).json({
        success: true,
        data: categoriesWithCount
    });
});

// @desc    Create new blog post
// @route   POST /api/blog
// @access  Private (Admin only)
exports.createBlog = asyncHandler(async (req, res) => {
    // Calculate read time automatically
    if (req.body.content) {
        const wordsPerMinute = 200;
        const wordCount = req.body.content.split(/\s+/).length;
        req.body.readTime = Math.ceil(wordCount / wordsPerMinute);
    }

    const blog = await Blog.create(req.body);

    res.status(201).json({
        success: true,
        data: blog
    });
});

// @desc    Update blog post
// @route   PUT /api/blog/:id
// @access  Private (Admin only)
exports.updateBlog = asyncHandler(async (req, res) => {
    let blog = await Blog.findById(req.params.id);

    if (!blog) {
        return res.status(404).json({
            success: false,
            error: 'Article non trouvé'
        });
    }

    // Recalculate read time if content changed
    if (req.body.content) {
        const wordsPerMinute = 200;
        const wordCount = req.body.content.split(/\s+/).length;
        req.body.readTime = Math.ceil(wordCount / wordsPerMinute);
    }

    blog = await Blog.findByIdAndUpdate(req.params.id, req.body, {
        new: true,
        runValidators: true
    });

    res.status(200).json({
        success: true,
        data: blog
    });
});

// @desc    Delete blog post
// @route   DELETE /api/blog/:id
// @access  Private (Admin only)
exports.deleteBlog = asyncHandler(async (req, res) => {
    const blog = await Blog.findById(req.params.id);

    if (!blog) {
        return res.status(404).json({
            success: false,
            error: 'Article non trouvé'
        });
    }

    await blog.deleteOne();

    res.status(200).json({
        success: true,
        message: 'Article supprimé avec succès'
    });
});

// @desc    Like a blog post
// @route   POST /api/blog/:id/like
// @access  Public
exports.likeBlog = asyncHandler(async (req, res) => {
    const blog = await Blog.findById(req.params.id);

    if (!blog) {
        return res.status(404).json({
            success: false,
            error: 'Article non trouvé'
        });
    }

    blog.likes += 1;
    await blog.save();

    res.status(200).json({
        success: true,
        data: { likes: blog.likes }
    });
});

// @desc    Get blog statistics
// @route   GET /api/blog/stats
// @access  Private (Admin only)
exports.getBlogStats = asyncHandler(async (req, res) => {
    const totalBlogs = await Blog.countDocuments();
    const publishedBlogs = await Blog.countDocuments({ status: 'published' });
    const draftBlogs = await Blog.countDocuments({ status: 'draft' });
    const featuredBlogs = await Blog.countDocuments({ featured: true, status: 'published' });
    
    // Total views across all blogs
    const viewsResult = await Blog.aggregate([
        { $group: { _id: null, totalViews: { $sum: '$views' } } }
    ]);
    const totalViews = viewsResult.length > 0 ? viewsResult[0].totalViews : 0;

    // Most popular articles
    const popularArticles = await Blog.find({ status: 'published' })
        .sort({ views: -1 })
        .limit(5)
        .select('title views publishedAt');

    // Recent articles
    const recentArticles = await Blog.find({ status: 'published' })
        .sort({ publishedAt: -1 })
        .limit(5)
        .select('title publishedAt');

    res.status(200).json({
        success: true,
        data: {
            totals: {
                total: totalBlogs,
                published: publishedBlogs,
                draft: draftBlogs,
                featured: featuredBlogs,
                totalViews
            },
            popularArticles,
            recentArticles
        }
    });
});
