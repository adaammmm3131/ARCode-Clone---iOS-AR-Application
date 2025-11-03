# Phase 27 - Testing - Guide Complet

## Vue d'ensemble

Phase 27 met en place une suite de tests complète pour iOS et backend avec couverture de code, tests d'intégration, et load testing.

## Phase 27.1 - Tests Unitaires Swift

### Structure

```
Tests/
├── ARCodeCloneTests/
│   ├── UnitTests/
│   │   ├── Models/
│   │   │   └── ARCodeTests.swift
│   │   ├── Services/
│   │   │   ├── NetworkServiceTests.swift
│   │   │   └── QRCodeGenerationServiceTests.swift
│   │   └── ViewModels/
│   │       └── QRCodeViewModelTests.swift
│   ├── IntegrationTests/
│   │   └── APIIntegrationTests.swift
│   ├── ARKitTests/
│   │   ├── ARPlaneDetectionTests.swift
│   │   └── ARPerformanceTests.swift
│   └── XCTestManifests.swift
```

### Tests créés

1. **Models Tests**
   - `ARCodeTests.swift` - Tests du modèle ARCode
   - Initialization, Codable, type enum

2. **Services Tests**
   - `NetworkServiceTests.swift` - Tests réseau avec mocks
   - `QRCodeGenerationServiceTests.swift` - Tests génération QR

3. **ViewModels Tests**
   - `QRCodeViewModelTests.swift` - Tests ViewModels avec DI
   - Mock services pour isolation

### Coverage Target

- **Target:** 80%+ coverage
- **CI Integration:** Workflow `ios-test-coverage.yml`
- **Tools:** Xcode Code Coverage, Codecov

## Phase 27.2 - Tests d'Intégration

### Backend Tests

**Structure:**
```
backend/tests/
├── conftest.py
├── test_api_health.py
├── test_api_auth.py
├── test_database_migrations.py
├── test_queue_jobs.py
└── load_test/
    ├── locustfile.py
    └── performance_benchmark.py
```

### Tests créés

1. **API Tests**
   - Health check endpoints
   - Authentication
   - Database migrations
   - Job queue

2. **Fixtures**
   - Mock database
   - Mock Redis
   - Mock network services
   - Test client Flask

### Configuration

**pytest.ini:**
- Coverage target: 80%+
- Markers: unit, integration, slow, arkit
- HTML reports

**CI Integration:**
- Workflow `backend-test.yml`
- Services PostgreSQL et Redis
- Coverage upload Codecov

## Phase 27.3 - Tests Devices

### iOS Simulators

**Matrix Testing:**
- iPhone 15 Pro (latest)
- iPhone 14
- iPad Pro (12.9-inch)

**Workflow:** `.github/workflows/ios-test.yml`

### Firebase Test Lab (Optionnel)

Pour tests Android et devices physiques:
- 50+ models Android
- Devices réels
- Automated testing

## Phase 27.4 - Load Testing

### Locust

**Fichier:** `backend/tests/load_test/locustfile.py`

**Scénarios:**
- 1M users simulation
- 100K simultaneous users
- Stress testing

**Usage:**
```bash
locust -f locustfile.py --host=https://ar-code.com --users 100000 --spawn-rate 1000
```

### Performance Benchmark

**Fichier:** `backend/tests/load_test/performance_benchmark.py`

**Métriques:**
- Response time (avg, median, p95, p99)
- Throughput
- Error rate
- Success rate

## ARKit Testing

### Simulation Tests

**Fichier:** `Tests/ARCodeCloneTests/ARKitTests/ARPlaneDetectionTests.swift`

**Tests:**
- AR configuration creation
- Plane detection
- Face tracking
- Image tracking

### Performance Tests

**Fichier:** `Tests/ARCodeCloneTests/ARKitTests/ARPerformanceTests.swift`

**Targets:**
- 60fps rendering
- <50ms latency
- <150MB memory

## Mock Services

### iOS Mocks

- `MockNetworkService` - Network mocking
- `MockQRCodeGenerationService` - QR generation
- `MockQRCodeURLService` - URL service
- `MockQRCodeDesignService` - Design service

### Backend Mocks

- `mock_db` - Database fixtures
- `mock_redis` - Redis fixtures
- `mock_network_service` - Network mocking

## CI Integration

### iOS Tests

**Workflow:** `.github/workflows/ios-test.yml`
- Multi-device matrix
- Coverage generation
- Codecov upload

**Coverage Workflow:** `.github/workflows/ios-test-coverage.yml`
- Coverage threshold check (80%)
- Fails if below threshold

### Backend Tests

**Workflow:** `.github/workflows/backend-test.yml`
- PostgreSQL service
- Redis service
- Unit tests
- Integration tests
- Coverage reporting

## Checklist Phase 27

- [x] Unit tests Swift (Models, Services, ViewModels)
- [x] Mock services
- [x] Integration tests API
- [x] Database tests
- [x] ARKit simulation tests
- [x] Performance tests
- [x] Load testing (Locust)
- [x] Performance benchmarks
- [x] CI integration
- [x] Coverage reporting (80%+)

## Prochaines étapes

Voir Phase 28 - Features pour:
- Custom links
- Collaboration
- White label







