# Configuration Management

The Standards API uses Apple's [Swift Configuration](https://github.com/apple/swift-configuration) library
for unified configuration management across all deployment environments.

## Environment Detection

Both `StandardsAPI` and `StandardsAPIServer` use the **ENV environment variable** to determine their runtime behavior:

```bash
# Development mode (Vapor HTTP server, SQLite database)
ENV=development swift run StandardsAPIServer

# Production mode (AWS Lambda runtime, PostgreSQL database)
ENV=production swift run StandardsAPI
```

### How It Works

The Swift Configuration library automatically transforms configuration keys to environment variables:

- Configuration key: `"env"`
- Environment variable: `ENV` (uppercase transformation)

```swift
import Configuration

let config = ConfigReader(provider: EnvironmentVariablesProvider())
let environment = config.string(forKey: "env", default: "development")
```

### No Translation Logic

Following best practices, there is **no complex if-else translation logic** to detect the runtime environment. The implementation:

1. Reads **only** the `ENV` environment variable
2. Uses a simple switch statement to choose the transport
3. Defaults to `development` if ENV is not set

```swift
switch environment {
case "production":
    try await runLambda()    // AWS Lambda runtime
default:
    try await runVapor()     // Vapor HTTP server
}
```

## Available Environments

| ENV Value                | Runtime    | Database   | Use Case              |
| ------------------------ | ---------- | ---------- | --------------------- |
| `development` (default)  | Vapor HTTP | SQLite     | Local development     |
| `production`             | AWS Lambda | PostgreSQL | Production deployment |

## Configuration Architecture

### Shared Implementation

Both executables share the same API implementation (`StandardsAPIImplementation`) which:

- Implements all OpenAPI endpoints
- Contains business logic
- Is transport-agnostic

### Transport Adapters

Each runtime has a thin adapter layer:

- **LambdaAdapter**: Wraps the implementation for `OpenAPILambdaHttpApi`
- **VaporTransport**: Integrates with Vapor via `OpenAPIVapor`

### File Structure

```txt
Sources/
  StandardsAPI/
    main.swift                      # Unified entry point with ENV detection
    StandardsAPIImplementation.swift # Shared API implementation
  StandardsAPIServer/
    main.swift                      # Vapor server with ENV logging
```

## Local Development

Run the Vapor server locally:

```bash
# Explicit environment variable
ENV=development swift run StandardsAPIServer

# Or rely on default
swift run StandardsAPIServer
```

The server will:

1. Read ENV variable using Swift Configuration
2. Log the detected environment
3. Start Vapor HTTP server on <http://localhost:8080>
4. Serve Swagger UI at the homepage

## Production Deployment

Deploy to AWS Lambda:

```bash
# Build for Lambda
swift build -c release --product StandardsAPI

# Package for Lambda
./scripts/package-lambda.sh

# Deploy with ENV=production set in Lambda configuration
```

The Lambda function will:

1. Read ENV=production from Lambda environment variables
2. Initialize AWS Lambda Runtime
3. Handle API Gateway requests

## Configuration Values

The Configuration library supports reading additional values beyond `ENV`:

```swift
let config = ConfigReader(provider: EnvironmentVariablesProvider())

// Database configuration
let dbHost = config.string(forKey: "database.host", default: "localhost")
// Reads: DATABASE_HOST environment variable

// Timeouts
let httpTimeout = config.int(forKey: "http.timeout", default: 60)
// Reads: HTTP_TIMEOUT environment variable
```

### Key Transformation Rules

The library automatically transforms dotted notation to environment variables:

- `"env"` → `ENV`
- `"database.host"` → `DATABASE_HOST`
- `"http.timeout"` → `HTTP_TIMEOUT`
- `"api.key"` → `API_KEY`

All transformations:

1. Convert to uppercase
2. Replace dots with underscores
3. No special logic needed

## Benefits

### 1. No Complex Detection Logic

❌ **Old Approach** (avoid):

```swift
if ProcessInfo.processInfo.environment["AWS_LAMBDA_FUNCTION_NAME"] != nil {
    // Use Lambda
} else if ProcessInfo.processInfo.environment["KUBERNETES_SERVICE_HOST"] != nil {
    // Use Kubernetes
} else {
    // Use local
}
```

✅ **New Approach** (preferred):

```swift
let config = ConfigReader(provider: EnvironmentVariablesProvider())
let environment = config.string(forKey: "env", default: "development")
```

### 2. Type-Safe Configuration

The Configuration library provides type-safe access to config values with automatic conversion.

### 3. Consistent Across Projects

Using Swift Configuration ensures consistency across all Sagebrush projects and follows Apple's recommended patterns.

### 4. Testable

Easy to test different environments by mocking the ConfigReader.

## References

- [Swift Configuration Documentation](https://github.com/apple/swift-configuration)
- [EnvironmentVariablesProvider API](https://github.com/apple/swift-configuration/blob/main/Sources/Configuration/Providers/EnvironmentVariables/EnvironmentVariablesProvider.swift)
