import { Helmet } from 'react-helmet-async'

interface SEOHeadProps {
  title: string
  description: string
  keywords?: string
  image?: string
  url?: string
  type?: 'website' | 'article'
}

export default function SEOHead({
  title,
  description,
  keywords = 'location résidence Côte d\'Ivoire, logement Abidjan, appartement meublé, villa luxueuse, gestion locative',
  image,
  url,
  type = 'website'
}: SEOHeadProps) {
  const baseUrl = import.meta.env.VITE_SITE_URL?.trim() || 'https://presentation.chapechaperesidence.com'
  const defaultImage = `${baseUrl}/assets/logo.png`
  const fullUrl = url || `${baseUrl}/`
  const fullTitle = `${title} - ChapeChape Residence`
  
  return (
    <Helmet>
      {/* Basic Meta Tags */}
      <title>{fullTitle}</title>
      <meta name="description" content={description} />
      <meta name="keywords" content={keywords} />
      <link rel="canonical" href={fullUrl} />
      
      {/* Open Graph / Facebook */}
      <meta property="og:type" content={type} />
      <meta property="og:url" content={fullUrl} />
      <meta property="og:title" content={fullTitle} />
      <meta property="og:description" content={description} />
      <meta property="og:image" content={image || defaultImage} />
      
      {/* Twitter */}
      <meta property="twitter:card" content="summary_large_image" />
      <meta property="twitter:url" content={fullUrl} />
      <meta property="twitter:title" content={fullTitle} />
      <meta property="twitter:description" content={description} />
      <meta property="twitter:image" content={image || defaultImage} />
    </Helmet>
  )
}
