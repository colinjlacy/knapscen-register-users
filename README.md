# knapscen-register-users

A Python script that registers user information in a MySQL database and publishes events to NATS JetStream.

## Features

- Registers users in the `users` table with proper foreign key relationships
- Supports lookup by customer name or role name (in addition to IDs)
- Publishes events to NATS JetStream with user data
- Comprehensive error handling and logging
- Environment variable-based configuration

## Requirements

- Python 3.7+
- MySQL database with the required schema (see `database_schema.sql`)
- NATS server with JetStream enabled

## Installation

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Set up your environment variables (see `env.example` for reference)

## Usage

### Environment Variables

The script requires the following environment variables:

**User Information (required):**
- `USER_NAME`: Full name of the user
- `USER_EMAIL`: Email address of the user

**Customer Information (one required):**
- `CUSTOMER_ID`: UUID of the corporate customer, OR
- `CUSTOMER_NAME`: Name of the corporate customer (will lookup ID)

**Role Information (one required):**
- `ROLE_ID`: UUID of the user role, OR
- `ROLE_NAME`: Name of the role (e.g., 'customer_account_owner', 'admin_user', 'generic_user')

**Database Connection (required):**
- `DB_HOST`: Database hostname
- `DB_PORT`: Database port (default: 3306)
- `DB_USER`: Database username
- `DB_PASSWORD`: Database password
- `DB_NAME`: Database name

**NATS Connection (required):**
- `NATS_SERVER`: NATS server URL (e.g., nats://localhost:4222)
- `NATS_STREAM`: JetStream stream name
- `NATS_SUBJECT`: Subject to publish events to
- `NATS_USER`: NATS username (optional, for authenticated servers)
- `NATS_PASSWORD`: NATS password (optional, for authenticated servers)

### Running the Script

1. Set your environment variables:
   ```bash
   export USER_NAME="John Doe"
   export USER_EMAIL="john.doe@example.com"
   export CUSTOMER_NAME="TechCorp Solutions"
   export ROLE_NAME="customer_account_owner"
   export DB_HOST="localhost"
   export DB_USER="myuser"
   export DB_PASSWORD="mypassword"
   export DB_NAME="scaffold_db"
   export NATS_URL="nats://localhost:4222"
   export NATS_STREAM="user_events"
   export NATS_SUBJECT="users.registered"
   ```

2. Run the script:
   ```bash
   python register_user.py
   ```

### Testing with the Test Script

A comprehensive test script `test_register_user.sh` is provided to test different scenarios:

```bash
# Make the script executable (if not already)
chmod +x test_register_user.sh

# Run a specific test scenario
./test_register_user.sh 1    # Test with name lookups (recommended)
./test_register_user.sh 3    # Test admin user registration
./test_register_user.sh 4    # Test generic user registration

# Run all applicable scenarios
./test_register_user.sh all

# Show help
./test_register_user.sh help
```

The test script provides multiple scenarios:
- **Scenario 1**: Register user using customer/role name lookup (recommended)
- **Scenario 2**: Register user using direct UUIDs (requires database setup)
- **Scenario 3**: Register admin user with name lookup
- **Scenario 4**: Register generic user with name lookup

The script includes proper error handling, colored output, and uses environment variables that align with common deployment patterns.

## Docker Support

### Building and Running with Docker

The application is containerized and supports multi-architecture builds (amd64/arm64):

```bash
# Build the Docker image locally
docker build -t knapscen-register-users .

# Run with environment variables
docker run --rm \
  -e USER_NAME="John Doe" \
  -e USER_EMAIL="john.doe@example.com" \
  -e CUSTOMER_NAME="TechCorp Solutions" \
  -e ROLE_NAME="customer_account_owner" \
  -e DB_HOST="your-db-host" \
  -e DB_USER="your-db-user" \
  -e DB_PASSWORD="your-db-password" \
  -e DB_NAME="your-db-name" \
  -e NATS_URL="nats://your-nats-host:4222" \
  -e NATS_STREAM="user_events" \
  -e NATS_SUBJECT="users.registered" \
  -e NATS_USER="your-nats-user" \
  -e NATS_PASSWORD="your-nats-password" \
  knapscen-register-users
```

### Using Docker Compose

A complete `docker-compose.yml` is provided for local testing with MySQL and NATS:

```bash
# Start all services (MySQL, NATS, and the registration script)
docker-compose up

# Run only the registration script (assuming external DB/NATS)
docker-compose run --rm user-register
```

### GitHub Container Registry

Multi-architecture images are automatically built and pushed to GitHub Container Registry:

```bash
# Pull and run the latest image
docker run --rm \
  --env-file your-env-file \
  ghcr.io/colinjlacy/knapscen-register-users:latest
```

### Using with Kubernetes

A complete Kubernetes example with ConfigMap and Secret is provided in `k8s-example.yml`:

```bash
# Apply the Kubernetes resources
kubectl apply -f k8s-example.yml

# Check job status
kubectl get jobs
kubectl logs job/register-user
```

The Kubernetes deployment includes:
- **ConfigMap**: For non-sensitive configuration
- **Secret**: For database and NATS credentials
- **Job**: One-time execution of user registration
- **Resource limits**: Appropriate CPU/memory constraints

You can customize the user-specific environment variables in the Job spec:

```yaml
env:
  - name: USER_NAME
    value: "Jane Smith"
  - name: USER_EMAIL
    value: "jane.smith@company.com"
  - name: CUSTOMER_NAME
    value: "TechCorp Solutions"
  - name: ROLE_NAME
    value: "admin_user"
```

## Event Payload

When a user is successfully registered, an event is published to NATS JetStream with the following structure:

```json
{
  "event_type": "user_registered",
  "user_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "timestamp": "1234567890.123",
  "data": {
    "user_name": "John Doe",
    "user_email": "john.doe@example.com",
    "customer_name": "TechCorp Solutions",
    "role_name": "customer_account_owner"
  }
}
```

The event payload includes all environment variables except database connection info (`DB_*`) and NATS connection info (`NATS_*`).

## Error Handling

The script provides comprehensive error handling for:
- Missing required environment variables
- Database connection issues
- Duplicate email addresses
- Invalid customer or role references
- NATS connection and publishing failures

All errors are logged and the script exits with appropriate error codes.

## Database Schema

The script expects the database schema defined in `database_schema.sql`. Key requirements:
- `corporate_customers` table with customer data
- `user_roles` table with available roles
- `users` table with foreign key relationships

Available roles (as defined in the schema):
- `customer_account_owner`: Primary account holder
- `admin_user`: Administrative privileges
- `generic_user`: Standard user access
