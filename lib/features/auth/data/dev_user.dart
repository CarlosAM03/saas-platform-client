import 'package:flutter/foundation.dart';

import '../../../shared/models/api_models.dart';

/// Usuario local SOLO para desarrollo UI/UX. Inactivo fuera de modo debug.
class DevUser {
  static const email = 'frontend';
  static const password = 'frontend';
  static const token = 'dev-ui-token';

  static bool matches(String e, String p) =>
      kDebugMode && e == email && p == password;

  static bool isToken(String? t) => kDebugMode && t == token;

  static AuthContext context() => AuthContext(
        accessToken: token,
        user: AuthUser(
          id: 'cdevuser00000000000000',
          name: 'Frontend Dev',
          email: 'frontend@dev.local',
          platformRole: null,
          status: 'ACTIVO',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        tenants: const [
          AuthTenant(
            id: 'cdevtenant0000000000000',
            name: 'Tenant de prueba',
            slug: 'dev-tenant',
            status: 'ACTIVO',
          ),
        ],
        currentTenantId: 'cdevtenant0000000000000',
      );
}