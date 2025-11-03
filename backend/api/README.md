# AR Data API - Documentation

API REST pour données dynamiques en AR avec authentification OAuth 2.0, rate limiting, et webhook support.

## Authentification OAuth 2.0

### Authorization Code Flow

1. **Authorization Request**
   ```
   GET /oauth/authorize?client_id={client_id}&redirect_uri={redirect_uri}&response_type=code&scope=read write
   ```

2. **Token Exchange**
   ```
   POST /oauth/token
   Content-Type: application/json
   
   {
     "grant_type": "authorization_code",
     "code": "{authorization_code}",
     "client_id": "{client_id}",
     "client_secret": "{client_secret}",
     "redirect_uri": "{redirect_uri}"
   }
   ```

3. **Token Response**
   ```json
   {
     "access_token": "string",
     "refresh_token": "string",
     "token_type": "Bearer",
     "expires_in": 3600,
     "scope": "read write"
   }
   ```

### Refresh Token

```
POST /oauth/token
Content-Type: application/json

{
  "grant_type": "refresh_token",
  "refresh_token": "{refresh_token}",
  "client_id": "{client_id}",
  "client_secret": "{client_secret}"
}
```

## Endpoints Data API

### GET /api/v1/data

Récupérer données dynamiques.

**Headers:**
- `Authorization: Bearer {access_token}`

**Query Parameters:**
- `type` (optional): Type de données (`iot`, `pricing`, `member_card`, `generic`)
- `template` (optional): Template d'affichage

**Response:**
```json
{
  "data": {
    "key1": "value1",
    "key2": 123,
    "key3": 45.67
  },
  "timestamp": "2024-01-01T12:00:00Z",
  "source": "iot_generic",
  "template": "generic"
}
```

## Webhooks

### POST /api/v1/webhooks/register

Enregistrer un webhook pour notifications.

**Request:**
```json
{
  "url": "https://votreserveur.com/webhook",
  "events": ["data.updated", "data.created"],
  "secret": "webhook_secret_for_validation"
}
```

**Response:**
```json
{
  "webhook_id": "webhook_123",
  "url": "https://votreserveur.com/webhook",
  "events": ["data.updated", "data.created"]
}
```

### Événements Webhook

- `data.updated`: Données mises à jour
- `data.created`: Nouvelles données créées
- `data.deleted`: Données supprimées
- `error.occurred`: Erreur survenue

## Rate Limiting

- **Default**: 100 requêtes par minute, 1000 par heure
- **Headers de réponse**:
  - `X-RateLimit-Limit`: Limite totale
  - `X-RateLimit-Remaining`: Requêtes restantes
  - `X-RateLimit-Reset`: Timestamp de réinitialisation

## Templates de Données

### IoT Data

```json
{
  "temperature": 22.5,
  "humidity": 55.0,
  "pressure": 1015.2,
  "status": "active"
}
```

### Live Pricing

```json
{
  "product_name": "Product Name",
  "price": 99.99,
  "price_change": -2.5,
  "change_percent": -2.5,
  "currency": "EUR"
}
```

### Member Card

```json
{
  "name": "John Doe",
  "member_id": "MEM123456",
  "status": "active",
  "points": 1250
}
```

## Erreurs

### 401 Unauthorized
```json
{
  "error": "unauthorized",
  "message": "Token manquant ou invalide"
}
```

### 429 Too Many Requests
```json
{
  "error": "rate_limit_exceeded",
  "message": "Limite de requêtes dépassée"
}
```

### 400 Bad Request
```json
{
  "error": "invalid_request",
  "message": "Requête invalide"
}
```

## Exemples d'utilisation

### iOS Swift

```swift
let dataService = ARDataAPIService(...)

dataService.fetchData(endpoint: "/api/v1/data?type=iot&template=iot", parameters: nil) { result in
    switch result {
    case .success(let response):
        print("Data: \(response.data)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Subscription avec Combine

```swift
let publisher = dataService.subscribeToUpdates(
    endpoint: "/api/v1/data?type=pricing",
    interval: 5.0
)

publisher.sink { response in
    print("Updated data: \(response.data)")
}
```

## Sécurité

- **HTTPS**: Tous les endpoints requièrent HTTPS
- **OAuth 2.0**: Authentification obligatoire
- **Rate Limiting**: Protection contre abus
- **Webhook Signatures**: Validation avec secret partagé









