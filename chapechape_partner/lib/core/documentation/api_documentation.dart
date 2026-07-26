import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_config_manager.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

/// Classe utilitaire pour générer la documentation de l'API
class ApiDocumentation {
  /// Génère la documentation OpenAPI (Swagger) pour les endpoints
  static Map<String, dynamic> generateOpenApiSpec() {
    return {
      'openapi': '3.0.0',
      'info': {
        'title': 'ChapeChape Residence API',
        'version': '1.0.0',
        'description': 'API pour la gestion des résidences et réservations ChapeChape'
      },
      'servers': [
        {
          'url': AppConfigManager.apiBaseUrl,
          'description': 'Serveur ${AppConfigManager.environment}'
        }
      ],
      'paths': _generatePaths(),
      'components': {
        'schemas': _generateSchemas(),
        'securitySchemes': {
          'bearerAuth': {
            'type': 'http',
            'scheme': 'bearer',
            'bearerFormat': 'JWT'
          }
        }
      }
    };
  }

  /// Génère les chemins (endpoints) de l'API
  static Map<String, dynamic> _generatePaths() {
    return {
      // Endpoints de Réservation
      '/api/bookings/all': {
        'get': {
          'summary': 'Liste des réservations (admin)',
          'description': 'Récupère la liste de toutes les réservations (accès admin)',
          'tags': ['Réservations'],
          'security': [{'bearerAuth': []}],
          'parameters': [
            {
              'name': 'page',
              'in': 'query',
              'description': 'Numéro de page',
              'schema': {'type': 'integer', 'default': 1}
            },
            {
              'name': 'limit',
              'in': 'query',
              'description': 'Nombre d\'éléments par page',
              'schema': {'type': 'integer', 'default': 10}
            }
          ],
          'responses': {
            '200': {
              'description': 'Liste des réservations',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'data': {
                        'type': 'array',
                        'items': {'\$ref': '#/components/schemas/Booking'}
                      },
                      'pagination': {'\$ref': '#/components/schemas/Pagination'}
                    }
                  }
                }
              }
            },
            '401': {'description': 'Non autorisé'},
            '403': {'description': 'Accès interdit'},
            '500': {'description': 'Erreur serveur'}
          }
        }
      },
      '/api/bookings/user': {
        'get': {
          'summary': 'Réservations de l\'utilisateur',
          'description': 'Récupère les réservations de l\'utilisateur connecté',
          'tags': ['Réservations'],
          'security': [{'bearerAuth': []}],
          'parameters': [
            {
              'name': 'page',
              'in': 'query',
              'description': 'Numéro de page',
              'schema': {'type': 'integer', 'default': 1}
            },
            {
              'name': 'limit',
              'in': 'query',
              'description': 'Nombre d\'éléments par page',
              'schema': {'type': 'integer', 'default': 10}
            }
          ],
          'responses': {
            '200': {
              'description': 'Liste des réservations de l\'utilisateur',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'data': {
                        'type': 'array',
                        'items': {'\$ref': '#/components/schemas/Booking'}
                      },
                      'pagination': {'\$ref': '#/components/schemas/Pagination'}
                    }
                  }
                }
              }
            },
            '401': {'description': 'Non autorisé'},
            '500': {'description': 'Erreur serveur'}
          }
        }
      },
      '/api/bookings/{id}': {
        'get': {
          'summary': 'Détails d\'une réservation',
          'description': 'Récupère les détails d\'une réservation spécifique',
          'tags': ['Réservations'],
          'security': [{'bearerAuth': []}],
          'parameters': [
            {
              'name': 'id',
              'in': 'path',
              'description': 'ID de la réservation',
              'required': true,
              'schema': {'type': 'string'}
            }
          ],
          'responses': {
            '200': {
              'description': 'Détails de la réservation',
              'content': {
                'application/json': {
                  'schema': {'\$ref': '#/components/schemas/Booking'}
                }
              }
            },
            '401': {'description': 'Non autorisé'},
            '404': {'description': 'Réservation non trouvée'},
            '500': {'description': 'Erreur serveur'}
          }
        }
      },
      '/api/bookings/{id}/confirm': {
        'post': {
          'summary': 'Confirmer une réservation',
          'description': 'Confirme une réservation en attente',
          'tags': ['Réservations'],
          'security': [{'bearerAuth': []}],
          'parameters': [
            {
              'name': 'id',
              'in': 'path',
              'description': 'ID de la réservation',
              'required': true,
              'schema': {'type': 'string'}
            }
          ],
          'responses': {
            '200': {
              'description': 'Réservation confirmée',
              'content': {
                'application/json': {
                  'schema': {'\$ref': '#/components/schemas/Booking'}
                }
              }
            },
            '401': {'description': 'Non autorisé'},
            '403': {'description': 'Action non autorisée'},
            '404': {'description': 'Réservation non trouvée'},
            '500': {'description': 'Erreur serveur'}
          }
        }
      },
      '/api/bookings/{id}/cancel': {
        'post': {
          'summary': 'Annuler une réservation',
          'description': 'Annule une réservation',
          'tags': ['Réservations'],
          'security': [{'bearerAuth': []}],
          'parameters': [
            {
              'name': 'id',
              'in': 'path',
              'description': 'ID de la réservation',
              'required': true,
              'schema': {'type': 'string'}
            }
          ],
          'requestBody': {
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    'reason': {
                      'type': 'string',
                      'description': 'Raison de l\'annulation'
                    }
                  }
                }
              }
            }
          },
          'responses': {
            '200': {
              'description': 'Réservation annulée',
              'content': {
                'application/json': {
                  'schema': {'\$ref': '#/components/schemas/Booking'}
                }
              }
            },
            '401': {'description': 'Non autorisé'},
            '403': {'description': 'Action non autorisée'},
            '404': {'description': 'Réservation non trouvée'},
            '500': {'description': 'Erreur serveur'}
          }
        }
      },
      '/api/bookings/{id}/complete': {
        'post': {
          'summary': 'Marquer comme terminée',
          'description': 'Marque une réservation comme terminée',
          'tags': ['Réservations'],
          'security': [{'bearerAuth': []}],
          'parameters': [
            {
              'name': 'id',
              'in': 'path',
              'description': 'ID de la réservation',
              'required': true,
              'schema': {'type': 'string'}
            }
          ],
          'responses': {
            '200': {
              'description': 'Réservation terminée',
              'content': {
                'application/json': {
                  'schema': {'\$ref': '#/components/schemas/Booking'}
                }
              }
            },
            '401': {'description': 'Non autorisé'},
            '403': {'description': 'Action non autorisée'},
            '404': {'description': 'Réservation non trouvée'},
            '500': {'description': 'Erreur serveur'}
          }
        }
      },
      
      // Endpoints Résidences
      '/api/residences': {
        'get': {
          'summary': 'Liste des résidences',
          'description': 'Récupère la liste des résidences disponibles',
          'tags': ['Résidences'],
          'parameters': [
            {
              'name': 'page',
              'in': 'query',
              'description': 'Numéro de page',
              'schema': {'type': 'integer', 'default': 1}
            },
            {
              'name': 'limit',
              'in': 'query',
              'description': 'Nombre d\'éléments par page',
              'schema': {'type': 'integer', 'default': 10}
            },
            {
              'name': 'hasPool',
              'in': 'query',
              'description': 'Filtre pour les résidences avec piscine',
              'schema': {'type': 'boolean'}
            },
            {
              'name': 'isVacationResidence',
              'in': 'query',
              'description': 'Filtre pour les résidences de vacances',
              'schema': {'type': 'boolean'}
            }
          ],
          'responses': {
            '200': {
              'description': 'Liste des résidences',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'data': {
                        'type': 'array',
                        'items': {'\$ref': '#/components/schemas/Residence'}
                      },
                      'pagination': {'\$ref': '#/components/schemas/Pagination'}
                    }
                  }
                }
              }
            },
            '500': {'description': 'Erreur serveur'}
          }
        },
        'post': {
          'summary': 'Création de résidence',
          'description': 'Crée une nouvelle résidence',
          'tags': ['Résidences'],
          'security': [{'bearerAuth': []}],
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {'\$ref': '#/components/schemas/ResidenceCreate'}
              }
            }
          },
          'responses': {
            '201': {
              'description': 'Résidence créée',
              'content': {
                'application/json': {
                  'schema': {'\$ref': '#/components/schemas/Residence'}
                }
              }
            },
            '400': {'description': 'Données invalides'},
            '401': {'description': 'Non autorisé'},
            '500': {'description': 'Erreur serveur'}
          }
        }
      }
    };
  }

  /// Génère les schémas des modèles
  static Map<String, dynamic> _generateSchemas() {
    return {
      'Booking': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'residence': {'\$ref': '#/components/schemas/Residence'},
          'client': {'\$ref': '#/components/schemas/User'},
          'partner': {'\$ref': '#/components/schemas/User'},
          'status': {
            'type': 'string',
            'enum': ['pending', 'confirmed', 'cancelled', 'completed', 'refunded'],
            'description': 'Statut de la réservation'
          },
          'visitDate': {'type': 'string', 'format': 'date'},
          'visitTime': {'type': 'string'},
          'notes': {'type': 'string'},
          'createdAt': {'type': 'string', 'format': 'date-time'},
          'updatedAt': {'type': 'string', 'format': 'date-time'}
        }
      },
      'Residence': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'name': {'type': 'string'},
          'description': {'type': 'string'},
          'price': {'type': 'number'},
          'pricePeriod': {
            'type': 'string',
            'enum': ['daily', 'weekly', 'monthly', 'hourly']
          },
          'surface': {'type': 'number'},
          'rooms': {'type': 'integer'},
          'bedrooms': {'type': 'integer'},
          'bathrooms': {'type': 'integer'},
          'location': {'\$ref': '#/components/schemas/Location'},
          'images': {
            'type': 'array',
            'items': {'type': 'string'}
          },
          'mainImage': {'type': 'string'},
          'hasPool': {'type': 'boolean'},
          'hasWifi': {'type': 'boolean'},
          'hasRestaurant': {'type': 'boolean'},
          'isVacationResidence': {'type': 'boolean'},
          'isSpecialResidence': {'type': 'boolean'},
          'isAvailable': {'type': 'boolean'},
          'owner': {'\$ref': '#/components/schemas/User'},
          'createdAt': {'type': 'string', 'format': 'date-time'},
          'updatedAt': {'type': 'string', 'format': 'date-time'}
        }
      },
      'ResidenceCreate': {
        'type': 'object',
        'required': ['name', 'price', 'pricePeriod', 'location'],
        'properties': {
          'name': {'type': 'string'},
          'description': {'type': 'string'},
          'price': {'type': 'number'},
          'pricePeriod': {
            'type': 'string',
            'enum': ['daily', 'weekly', 'monthly', 'hourly']
          },
          'surface': {'type': 'number'},
          'rooms': {'type': 'integer'},
          'bedrooms': {'type': 'integer'},
          'bathrooms': {'type': 'integer'},
          'location': {'\$ref': '#/components/schemas/Location'},
          'hasPool': {'type': 'boolean'},
          'hasWifi': {'type': 'boolean'},
          'hasRestaurant': {'type': 'boolean'},
          'isVacationResidence': {'type': 'boolean'},
          'isSpecialResidence': {'type': 'boolean'},
          'isAvailable': {'type': 'boolean', 'default': true}
        }
      },
      'Location': {
        'type': 'object',
        'properties': {
          'address': {'type': 'string'},
          'city': {'type': 'string'},
          'state': {'type': 'string'},
          'country': {'type': 'string'},
          'zipCode': {'type': 'string'},
          'latitude': {'type': 'number'},
          'longitude': {'type': 'number'}
        }
      },
      'User': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'firstName': {'type': 'string'},
          'lastName': {'type': 'string'},
          'email': {'type': 'string'},
          'phone': {'type': 'string'},
          'role': {
            'type': 'string',
            'enum': ['client', 'partner', 'admin']
          },
          'avatar': {'type': 'string'},
          'createdAt': {'type': 'string', 'format': 'date-time'}
        }
      },
      'Pagination': {
        'type': 'object',
        'properties': {
          'currentPage': {'type': 'integer'},
          'totalPages': {'type': 'integer'},
          'totalItems': {'type': 'integer'},
          'perPage': {'type': 'integer'}
        }
      }
    };
  }

  /// Enregistre la spécification OpenAPI dans un fichier JSON
  static String getOpenApiJson() {
    final spec = generateOpenApiSpec();
    return const JsonEncoder.withIndent('  ').convert(spec);
  }
  
  /// Imprime la documentation OpenAPI dans la console (pour déboguer)
  static void printOpenApiSpec() {
    if (kDebugMode) {
      final jsonSpec = getOpenApiJson();
      AppLogger.d('=== DOCUMENTATION API ===');
      AppLogger.d(jsonSpec);
      AppLogger.d('========================');
    }
  }
}
