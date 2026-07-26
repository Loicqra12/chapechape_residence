'use strict'

/**
 * New Relic agent configuration.
 * 
 * See lib/config/default.js in the agent distribution for a more complete
 * description of configuration variables and their potential values.
 */
exports.config = {
  /**
   * Array of application names.
   */
  app_name: ['ChapeChape Residences Backend'],
  
  /**
   * Your New Relic license key.
   */
  license_key: process.env.NEW_RELIC_LICENSE_KEY || 'your-license-key-here',
  
  /**
   * This setting controls distributed tracing.
   * Distributed tracing lets you see the path that a request takes through your
   * distributed system. Enabling distributed tracing changes the behavior of some
   * New Relic features, so carefully consult the transition guide before you enable
   * this feature: https://docs.newrelic.com/docs/transition-guide-distributed-tracing
   * Default is true.
   */
  distributed_tracing: {
    /**
     * Enables/disables distributed tracing.
     *
     * @env NEW_RELIC_DISTRIBUTED_TRACING_ENABLED
     */
    enabled: true
  },
  
  logging: {
    /**
     * Level at which to log. 'trace' is most useful to New Relic when diagnosing
     * issues with the agent, 'info' and higher will impose the least overhead on
     * production applications.
     */
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    
    /**
     * Where to put the log file -- by default just uses process.cwd() +
     * 'newrelic_agent.log'
     */
    filepath: require('path').join(__dirname, 'logs', 'newrelic_agent.log'),
    
    /**
     * Whether to write to a log file at all
     */
    enabled: true
  },
  
  /**
   * When true, all request headers except for those listed in attributes.exclude
   * will be captured for all traces, unless otherwise specified in a destination's
   * attributes include/exclude lists.
   */
  allow_all_headers: true,
  
  attributes: {
    /**
     * Prefix of attributes to exclude from all destinations. Allows * as wildcard
     * at end.
     */
    exclude: [
      'request.headers.cookie',
      'request.headers.authorization',
      'request.headers.proxyAuthorization',
      'request.headers.setCookie*',
      'request.headers.x*',
      'response.headers.cookie',
      'response.headers.authorization',
      'response.headers.proxyAuthorization',
      'response.headers.setCookie*'
    ]
  },
  
  /**
   * Transaction tracer captures deep information about slow
   * transactions and sends this to the UI on a periodic basis. The
   * transaction tracer is enabled by default. Set this to false to turn it off.
   */
  transaction_tracer: {
    /**
     * Threshold in milliseconds. When the response time of a controller action
     * exceeds this threshold, a transaction trace will be recorded.
     */
    transaction_threshold: 'apdex_f',
    
    /**
     * Maximum number of transaction trace nodes to record in a single transaction.
     */
    top_n: 20,
    
    /**
     * Whether to record the parameters from a request for a transaction trace.
     */
    record_sql: 'obfuscated',
    
    /**
     * Obfuscate the SQL-like statements recorded for slow transactions.
     */
    explain_threshold: 500
  },
  
  /**
   * Error collector captures information about uncaught exceptions and
   * sends them to the UI for viewing. The error collector is enabled by default.
   * Set this to false to turn it off.
   */
  error_collector: {
    /**
     * Disables the error collector.
     */
    enabled: true,
    
    /**
     * List of HTTP error status codes the error collector should disregard.
     */
    ignore_status_codes: [401, 404],
    
    /**
     * Whether to record a stack trace with the recorded error.
     */
    capture_events: true,
    
    /**
     * The agent will collect all error events up to this number per minute.
     * If there are more than that, a statistical sampling will be collected.
     */
    max_event_samples_stored: 100
  },
  
  /**
   * Browser monitoring lets you correlate transactions between the server and browser.
   * This is achieved by injecting a small amount of JavaScript code into the HTML
   * response.
   */
  browser_monitoring: {
    /**
     * Enable browser monitoring header generation.
     */
    enable: false
  },
  
  /**
   * Application logging configuration
   */
  application_logging: {
    /**
     * Enables/disables the application logging features.
     */
    enabled: true,
    
    /**
     * Enables/disables forwarding of application logs to New Relic.
     */
    forwarding: {
      enabled: true,
      max_samples_stored: 10000
    },
    
    /**
     * Enables/disables local decoration of log messages with linking metadata.
     */
    local_decorating: {
      enabled: true
    }
  },
  
  /**
   * Rules for naming or ignoring transactions.
   */
  rules: {
    name: [
      // Rename health check endpoints
      { pattern: '/health', name: 'HealthCheck' },
      { pattern: '/api/health', name: 'APIHealthCheck' },
      
      // Group API endpoints
      { pattern: '/api/auth/*', name: 'AuthAPI/*' },
      { pattern: '/api/residences/*', name: 'ResidencesAPI/*' },
      { pattern: '/api/reservations/*', name: 'ReservationsAPI/*' },
      { pattern: '/api/partners/*', name: 'PartnersAPI/*' }
    ],
    
    ignore: [
      // Ignore static assets
      '/favicon.ico',
      '/robots.txt',
      '*.css',
      '*.js',
      '*.png',
      '*.jpg',
      '*.gif'
    ]
  },
  
  /**
   * Custom insights configuration
   */
  custom_insights_events: {
    enabled: true,
    max_samples_stored: 1000
  },
  
  /**
   * Slow query configuration
   */
  slow_sql: {
    enabled: true,
    max_samples_stored: 100
  }
}
