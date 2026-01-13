# Local Development Server

This guide explains how to run the Standards API locally with Swagger UI for interactive testing.

## Quick Start

```bash
# Build and run the local development server
swift run StandardsAPIServer

# Or specify host and port
swift run StandardsAPIServer serve --hostname 0.0.0.0 --port 8080
```

The server will start on `http://localhost:8080` with:

- **Swagger UI**: `http://localhost:8080/` (interactive API documentation)
- **OpenAPI Spec**: `http://localhost:8080/openapi.yaml`
- **API Endpoints**: All endpoints defined in `openapi.yaml`

## What's Included

### 🎨 Swagger UI

Beautiful, interactive API documentation where you can:

- Browse all available endpoints
- View request/response schemas
- Test endpoints directly from the browser
- See example requests and responses

### 📊 Sample Data

The server automatically loads 97 seed records:

- 1 Person (Nick Shook - <nick@neonlaw.com>)
- 1 User account
- 3 Bar credentials (Nevada, California, Washington)
- 6 Entities (Shook Law LLC, Neon Law, etc.)
- 52 Jurisdictions (all US states + DC + Germany)
- 22 Questions
- 1 Address (Sagebrush Services LLC)

### 🗄️ Database

Uses SQLite file-based database at `db/standards.sqlite` with all migrations applied.

## API Endpoints

### Health Check

```bash
curl http://localhost:8080/health
```

### List Persons

```bash
curl http://localhost:8080/persons
```

### Create Person

```bash
curl -X POST http://localhost:8080/persons \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test Person"
  }'
```

### List Entities

```bash
curl http://localhost:8080/entities
```

### List Jurisdictions

```bash
curl http://localhost:8080/jurisdictions
```

## Using Playwright

The server is designed to work with Playwright for automated testing:

```typescript
import { test, expect } from '@playwright/test';

test('API homepage loads', async ({ page }) => {
  await page.goto('http://localhost:8080');

  // Verify Swagger UI loaded
  await expect(page.locator('h1')).toContainText('Sagebrush Standards API');

  // Verify endpoints are visible
  await expect(page.locator('.opblock-tag')).toBeVisible();
});

test('Health endpoint works', async ({ request }) => {
  const response = await request.get('http://localhost:8080/health');
  expect(response.ok()).toBeTruthy();

  const data = await response.json();
  expect(data.status).toBe('healthy');
});
```

## PostgreSQL (Optional)

To use PostgreSQL instead of SQLite:

```bash
# Start PostgreSQL with Docker Compose
docker-compose up -d

# Set environment variables
export ENV=production
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_USERNAME=standards
export DATABASE_PASSWORD=standards
export DATABASE_NAME=standards

# Run server
swift run StandardsAPIServer
```

## Architecture

```txt
StandardsAPIServer
├── Vapor HTTP server (local development)
├── OpenAPI generator (type-safe request/response)
├── Swagger UI (interactive docs)
├── StandardsDAL (database layer)
└── Same API handlers as Lambda deployment
```

### Differences from Lambda

| Feature    | StandardsAPIServer (Local) | StandardsAPI (Lambda)    |
| ---------- | -------------------------- | ------------------------ |
| Transport  | Vapor HTTP                 | AWS Lambda + API Gateway |
| Database   | SQLite file                | Aurora PostgreSQL        |
| Swagger UI | ✅ Included                 | ❌ Not included           |
| Hot Reload | ✅ Yes                      | ❌ No                     |
| Deployment | Local only                 | AWS Cloud                |

Both use the **same OpenAPI specification** and **same API implementation**, ensuring consistency
between local development and production.

## Troubleshooting

### Port Already in Use

```bash
# Kill any existing server
pkill -f StandardsAPIServer

# Or use a different port
swift run StandardsAPIServer serve --port 3000
```

### Database Locked

```bash
# Remove the SQLite database
rm db/standards.sqlite

# Restart the server (will recreate database)
swift run StandardsAPIServer
```

### Swagger UI Not Loading

1. Ensure `Public/index.html` exists
2. Check server logs for "Public directory" path
3. Verify files are in the correct location

## Next Steps

1. **Implement Service Layer**: Replace stub implementations with actual database queries
2. **Add Authentication**: Integrate JWT validation for secured endpoints
3. **Custom Endpoints**: Add new endpoints to `openapi.yaml` and regenerate
4. **Integration Tests**: Write Playwright tests for all endpoints

## Related Files

- `openapi.yaml` - API specification
- `Sources/StandardsAPI/` - Lambda deployment version
- `Sources/StandardsAPIServer/` - Local development version
- `Sources/StandardsDAL/` - Shared database layer
- `docker-compose.yml` - PostgreSQL setup
