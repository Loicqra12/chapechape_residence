/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string
  readonly VITE_SITE_URL: string
  readonly VITE_CLIENT_APP_URL: string
  readonly VITE_PARTNER_APP_URL: string
  readonly VITE_ADMIN_APP_URL: string
  // add more env variables here...
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
