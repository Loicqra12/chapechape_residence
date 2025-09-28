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
        print('🔐 [DEBUG] Token trouvé: ${token != null ? 'OUI' : 'NON'}');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔐 [DEBUG] Headers ajoutés: ${options.headers}');
        } else {
          print('❌ [DEBUG] Aucun token trouvé dans le stockage sécurisé');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: const [
          Tab(text: 'Historique', icon: Icon(Icons.history)),
          Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
          Tab(text: 'Journal', icon: Icon(Icons.list_alt)),
        ],
      ),
    );
  }

  Widget _buildSecurityHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_securityHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun historique de sécurité disponible'),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune statistique disponible'),
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
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune activité enregistrée'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques de Sécurité (30 derniers jours)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                  child: _buildStatItem(
                    'Total Activités',
                    _securityStats!.totalActivities.toString(),
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: _buildStatItem(
                    'Activités Suspectes',
                    _securityStats!.suspiciousActivities.toString(),
                    Icons.warning,
                    Colors.orange,
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
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: _buildStatItem(
                    'Risque Élevé',
                    _securityStats!.highRiskActivities.toString(),
                    Icons.dangerous,
                    Colors.purple,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskScoreCard() {
    final riskScore = _securityStats!.averageRiskScore;
    Color riskColor;
    String riskLevel;
    
    if (riskScore < 30) {
      riskColor = Colors.green;
      riskLevel = 'FAIBLE';
    } else if (riskScore < 60) {
      riskColor = Colors.orange;
      riskLevel = 'MOYEN';
    } else {
      riskColor = Colors.red;
      riskLevel = 'ÉLEVÉ';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Score de Risque Moyen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              value: riskScore / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              strokeWidth: 8,
            ),
            const SizedBox(height: 16),
            Text(
              '${riskScore.toStringAsFixed(1)}% - $riskLevel',
              style: TextStyle(
                fontSize: 18,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(activity.severity),
          child: Text(
            activity.actionIcon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(activity.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${activity.module.toUpperCase()} • ${activity.action}'),
            if (activity.location != null)
              Text('📍 ${activity.location!.city}, ${activity.location!.country}'),
            Text('🕒 ${_formatDateTime(activity.createdAt)}'),
          ],
        ),
        trailing: activity.isSuspicious
            ? const Icon(Icons.warning, color: Colors.red)
            : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildActivityCard(SecurityActivity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSeverityColor(activity.severity),
          child: Text(
            activity.actionIcon,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        title: Text(activity.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${activity.module.toUpperCase()} • ${activity.action}'),
            if (activity.device != null)
              Text('📱 ${activity.device!.type} • ${activity.device!.os}'),
            Text('🕒 ${_formatDateTime(activity.createdAt)}'),
          ],
        ),
        trailing: SizedBox(
          width: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activity.isSuspicious)
                const Icon(Icons.warning, color: Colors.red, size: 14),
              Text(
                '${activity.riskScore}%',
                style: TextStyle(
                  fontSize: 10,
                  color: _getRiskScoreColor(activity.riskScore),
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

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskScoreColor(int riskScore) {
    if (riskScore < 30) return Colors.green;
    if (riskScore < 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
