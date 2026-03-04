import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/api/audit_service.dart';
import '../../../core/config/app_config_manager.dart';
import '../../widgets/layout/screen_app_bars.dart';

/// Écran d'historique de sécurité pour les partenaires
class SecurityHistoryScreen extends StatefulWidget {
  const SecurityHistoryScreen({super.key});

  @override
  State<SecurityHistoryScreen> createState() => _SecurityHistoryScreenState();
}

class _SecurityHistoryScreenState extends State<SecurityHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AuditService _auditService;
  
  // État des données
  List<SecurityActivity> _securityHistory = [];
  List<SecurityActivity> _activityLog = [];
  SecurityStats? _securityStats;
  
  // État de chargement
  bool _isLoadingHistory = false;
  bool _isLoadingStats = false;
  bool _isLoadingLog = false;
  
  // Pagination
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  
  // Filtres
  String? _selectedModule;
  String? _selectedSeverity;
  
  final List<String> _modules = [
    'auth', 'profile', 'payment', 'residence', 'reservation', 'security', 'verification'
  ];
  
  final List<String> _severities = [
    'low', 'medium', 'high', 'critical'
  ];

  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Configurer Dio avec la base URL et l'authentification
    final dio = Dio(BaseOptions(
      baseUrl: AppConfigManager.apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Ajouter l'intercepteur d'authentification
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
    
    _auditService = AuditService(dio);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadSecurityHistory(),
      _loadSecurityStats(),
      _loadActivityLog(),
    ]);
  }

  Future<void> _loadSecurityHistory() async {
    setState(() => _isLoadingHistory = true);
    
    try {
      final result = await _auditService.getSecurityHistory(limit: 50);
      if (result.success) {
        setState(() {
          _securityHistory = result.history;
        });
      } else {
        _showErrorSnackBar(result.message ?? 'Erreur lors du chargement de l\'historique');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur de connexion: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadSecurityStats() async {
    setState(() => _isLoadingStats = true);
    
    try {
      final result = await _auditService.getSecurityStats(days: 30);
      if (result.success && result.stats != null) {
        setState(() {
          _securityStats = result.stats;
        });
      } else {
        _showErrorSnackBar(result.message ?? 'Erreur lors du chargement des statistiques');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur de connexion: $e');
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadActivityLog({bool loadMore = false}) async {
    if (loadMore) {
      _currentPage++;
    } else {
      setState(() {
        _currentPage = 1;
        _activityLog.clear();
        _hasMoreData = true;
      });
    }
    
    setState(() => _isLoadingLog = true);
    
    try {
      final result = await _auditService.getActivityLog(
        page: _currentPage,
        limit: _pageSize,
        module: _selectedModule,
        severity: _selectedSeverity,
      );
      
      if (result.success) {
        setState(() {
          if (loadMore) {
            _activityLog.addAll(result.activities);
          } else {
            _activityLog = result.activities;
          }
          _hasMoreData = result.pagination?.pages != null && 
                        _currentPage < result.pagination!.pages;
        });
      } else {
        _showErrorSnackBar(result.message ?? 'Erreur lors du chargement du journal');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur de connexion: $e');
    } finally {
      setState(() => _isLoadingLog = false);
    }
  }

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  IconData _getActionIconData(String action) {
    switch (action) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'login_failed':
        return Icons.block;
      case 'password_change':
        return Icons.lock_reset;
      case 'email_change':
        return Icons.email;
      case 'phone_change':
        return Icons.phone;
      case 'bank_account_change':
        return Icons.account_balance;
      case 'payout_initiated':
        return Icons.payments;
      case 'security_alert':
        return Icons.warning_amber_rounded;
      default:
        return Icons.history_edu;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ScreenAppBars.getSecurityHistoryAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildTabBar(),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSecurityHistoryTab(),
                      _buildSecurityStatsTab(),
                      _buildActivityLogTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        tabs: const [
          Tab(text: 'Historique', icon: Icon(Icons.history)),
          Tab(text: 'Statistiques', icon: Icon(Icons.analytics_outlined)),
          Tab(text: 'Journal', icon: Icon(Icons.format_list_bulleted)),
        ],
      ),
    );
  }

  Widget _buildSecurityHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_securityHistory.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Aucun historique de sécurité disponible',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSecurityHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _securityHistory.length,
        itemBuilder: (context, index) {
          final activity = _securityHistory[index];
          return _buildSecurityActivityCard(activity);
        },
      ),
    );
  }

  Widget _buildSecurityStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_securityStats == null) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Aucune statistique disponible',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSecurityStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildRiskScoreCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _isLoadingLog && _activityLog.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _activityLog.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_list_bulleted, size: 64, color: Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune activité enregistrée',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadActivityLog(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _activityLog.length + (_hasMoreData ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _activityLog.length) {
                            return _buildLoadMoreButton();
                          }
                          return _buildActivityCard(_activityLog[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          Column(
            children: [
              // Premier dropdown - Module
              DropdownButtonFormField<String>(
                value: _selectedModule,
                decoration: const InputDecoration(
                  labelText: 'Module',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous les modules')),
                  ..._modules.map((module) => DropdownMenuItem(
                    value: module,
                    child: Text(module.toUpperCase()),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedModule = value;
                  });
                  _loadActivityLog();
                },
              ),
              const SizedBox(height: 12),
              // Deuxième dropdown - Gravité
              DropdownButtonFormField<String>(
                value: _selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Gravité',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes les gravités')),
                  ..._severities.map((severity) => DropdownMenuItem(
                    value: severity,
                    child: Text(severity.toUpperCase()),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSeverity = value;
                  });
                  _loadActivityLog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildStatsCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques (30 derniers jours)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: _buildStatItem(
                    'Total Activités',
                    _securityStats!.totalActivities.toString(),
                    Icons.analytics_outlined,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: _buildStatItem(
                    'Suspectes',
                    _securityStats!.suspiciousActivities.toString(),
                    Icons.warning_amber_rounded,
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: _buildStatItem(
                    'Connexions Échouées',
                    _securityStats!.failedLogins.toString(),
                    Icons.block,
                    theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: _buildStatItem(
                    'Risque Élevé',
                    _securityStats!.highRiskActivities.toString(),
                    Icons.shield_outlined,
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRiskScoreCard() {
    final theme = Theme.of(context);
    final riskScore = _securityStats!.averageRiskScore;
    Color riskColor;
    String riskLevel;
    if (riskScore < 30) {
      riskColor = theme.colorScheme.primary;
      riskLevel = 'FAIBLE';
    } else if (riskScore < 60) {
      riskColor = theme.colorScheme.tertiary;
      riskLevel = 'MOYEN';
    } else {
      riskColor = theme.colorScheme.error;
      riskLevel = 'ÉLEVÉ';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Score de Risque Moyen',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              value: riskScore / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              strokeWidth: 8,
            ),
            const SizedBox(height: 16),
            Text(
              '${riskScore.toStringAsFixed(1)}% - $riskLevel',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityActivityCard(SecurityActivity activity) {
    final theme = Theme.of(context);
    final bgColor = _getSeverityColor(activity.severity, theme);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(
            _getActionIconData(activity.action),
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(activity.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${activity.module.toUpperCase()} • ${activity.action}'),
            if (activity.location != null)
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${activity.location!.city}, ${activity.location!.country}'),
                ],
              ),
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_formatDateTime(activity.createdAt)),
              ],
            ),
          ],
        ),
        trailing: activity.isSuspicious
            ? Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20)
            : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildActivityCard(SecurityActivity activity) {
    final theme = Theme.of(context);
    final bgColor = _getSeverityColor(activity.severity, theme);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(
            _getActionIconData(activity.action),
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(activity.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${activity.module.toUpperCase()} • ${activity.action}'),
            if (activity.device != null)
              Row(
                children: [
                  Icon(Icons.smartphone_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${activity.device!.type} • ${activity.device!.os}'),
                ],
              ),
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_formatDateTime(activity.createdAt)),
              ],
            ),
          ],
        ),
        trailing: SizedBox(
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activity.isSuspicious)
                Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 16),
              Text(
                '${activity.riskScore}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _getRiskScoreColor(activity.riskScore, theme),
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _hasMoreData ? () => _loadActivityLog(loadMore: true) : null,
        child: _isLoadingLog
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Charger plus'),
      ),
    );
  }

  Color _getSeverityColor(String severity, ThemeData theme) {
    switch (severity) {
      case 'low':
        return theme.colorScheme.primary.withOpacity(0.2);
      case 'medium':
        return theme.colorScheme.tertiary.withOpacity(0.25);
      case 'high':
      case 'critical':
        return theme.colorScheme.error.withOpacity(0.2);
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Color _getRiskScoreColor(int riskScore, ThemeData theme) {
    if (riskScore < 30) return theme.colorScheme.primary;
    if (riskScore < 60) return theme.colorScheme.tertiary;
    return theme.colorScheme.error;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
