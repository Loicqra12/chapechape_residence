module.exports = {
  apps: [{
    name: 'chapechape-residences-api',
    script: 'src/server.js',
    instances: 'max', // Utilise le nombre maximum de CPU disponibles
    exec_mode: 'cluster', // Mode cluster pour la mise à l'échelle
    autorestart: true, // Redémarrage automatique en cas de crash
    watch: false, // Désactivé en production
    max_memory_restart: '1G', // Redémarrage si la mémoire dépasse 1GB
    env: {
      NODE_ENV: 'production',
      PORT: 4000
    },
    env_development: {
      NODE_ENV: 'development',
      PORT: 4000
    },
    // Configuration des logs
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    error_file: 'logs/pm2/error.log',
    out_file: 'logs/pm2/output.log',
    merge_logs: true,
    // Monitoring
    monitor: true,
    // Métriques de performance
    metrics: {
      http: true,
      custom_metrics: [{
        id: 'requests/sec',
        format: 'metric',
        unit: 'req/s',
        agg_type: 'sum'
      }]
    },
    // Configuration des erreurs
    max_restarts: 10,
    min_uptime: '5s',
    // Hooks
    post_update: [
      'npm install',
      'npm run build'
    ],
    // Variables d'environnement spécifiques
    env_production: {
      NODE_ENV: 'production',
      PORT: 4000
    }
  }],

  // Configuration du déploiement
  deploy: {
    production: {
      user: 'ubuntu',
      host: ['your-production-server'],
      ref: 'origin/main',
      repo: 'git@github.com:your-repo/chapechape-residences.git',
      path: '/var/www/chapechape-residences',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production',
      env: {
        NODE_ENV: 'production'
      }
    },
    staging: {
      user: 'ubuntu',
      host: ['your-staging-server'],
      ref: 'origin/staging',
      repo: 'git@github.com:your-repo/chapechape-residences.git',
      path: '/var/www/chapechape-residences-staging',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env staging',
      env: {
        NODE_ENV: 'staging'
      }
    }
  }
};
