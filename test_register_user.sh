#!/bin/bash

# =============================================================================
# User Registration Test Script
# =============================================================================
# This script provides multiple test scenarios for the register_user.py script
# Based on common patterns and environment variables
# =============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to setup common environment variables
setup_common_env() {
    print_info "Setting up common environment variables..."
    
    # Database Configuration
    export DB_HOST="localhost"
    export DB_PORT="33006"
    export DB_USER="bassline-boogie-user"
    export DB_PASSWORD="8Qd8*yZK&zIxS%!s"
    export DB_NAME="bassline-boogie"

    # NATS JetStream Configuration
    export NATS_SERVER="nats://localhost:40953"
    export NATS_STREAM="customer-onboarding"
    export NATS_SUBJECT="user-saved"
    export NATS_USER="admin"
    export NATS_PASSWORD="admin"
    
    # Additional environment variables that will be included in events
    export ENVIRONMENT="${ENVIRONMENT:-development}"
    export SOURCE_SYSTEM="${SOURCE_SYSTEM:-test_script}"
    export DEPLOYMENT_VERSION="${DEPLOYMENT_VERSION:-v1.0.0}"
}

# Test scenario 1: Register user with customer and role names (lookup)
test_scenario_1() {
    print_info "Running Test Scenario 1: User registration with name lookups"
    
    export USER_NAME="John Smith"
    export USER_EMAIL="john.smith.test1@techcorp.com"
    export CUSTOMER_NAME="TechCorp Solutions"
    export ROLE_NAME="customer_account_owner"
    
    # Clear any existing ID variables to force name lookup
    unset CUSTOMER_ID ROLE_ID
    
    print_info "User: ${USER_NAME}"
    print_info "Email: ${USER_EMAIL}"
    print_info "Customer: ${CUSTOMER_NAME}"
    print_info "Role: ${ROLE_NAME}"
    
    python3 register_user.py
}

# Test scenario 2: Register user with direct IDs (if you have them)
test_scenario_2() {
    print_info "Running Test Scenario 2: User registration with direct IDs"
    
    export USER_NAME="Sarah Johnson"
    export USER_EMAIL="sarah.johnson.test2@startupxyz.com"
    
    # You'll need to replace these with actual UUIDs from your database
    # These are example UUIDs - replace with real ones from your corporate_customers and user_roles tables
    export CUSTOMER_ID="ef7caa53-f523-466d-83bf-5138dfcb1136"
    export ROLE_ID="1500cc35-099a-40cd-8669-62ff890fcbfe"
    
    # Clear name variables
    unset CUSTOMER_NAME ROLE_NAME
    
    print_warning "Note: Using example UUIDs - replace CUSTOMER_ID and ROLE_ID with real values from your database"
    print_info "User: ${USER_NAME}"
    print_info "Email: ${USER_EMAIL}"
    print_info "Customer ID: ${CUSTOMER_ID}"
    print_info "Role ID: ${ROLE_ID}"
    
    # Comment out the next line if you don't have real UUIDs
    python3 register_user.py
    # print_warning "Skipping scenario 2 - replace UUIDs with real values to test"
}

# Test scenario 3: Register admin user
test_scenario_3() {
    print_info "Running Test Scenario 3: Admin user registration"
    
    export USER_NAME="Mike Davis"
    export USER_EMAIL="mike.davis.test3@enterprise.com"
    export CUSTOMER_NAME="Enterprise Dynamics"
    export ROLE_NAME="admin_user"
    
    unset CUSTOMER_ID ROLE_ID
    
    print_info "User: ${USER_NAME}"
    print_info "Email: ${USER_EMAIL}"
    print_info "Customer: ${CUSTOMER_NAME}"
    print_info "Role: ${ROLE_NAME}"
    
    python3 register_user.py
}

# Test scenario 4: Register generic user
test_scenario_4() {
    print_info "Running Test Scenario 4: Generic user registration"
    
    export USER_NAME="Alice Brown"
    export USER_EMAIL="alice.brown.test4@innovationlabs.com"
    export CUSTOMER_NAME="Innovation Labs"
    export ROLE_NAME="generic_user"
    
    unset CUSTOMER_ID ROLE_ID
    
    print_info "User: ${USER_NAME}"
    print_info "Email: ${USER_EMAIL}"
    print_info "Customer: ${CUSTOMER_NAME}"
    print_info "Role: ${ROLE_NAME}"
    
    python3 register_user.py
}

# Function to run a specific scenario
run_scenario() {
    local scenario=$1
    echo
    print_info "=========================================="
    case $scenario in
        1)
            test_scenario_1
            ;;
        2)
            test_scenario_2
            ;;
        3)
            test_scenario_3
            ;;
        4)
            test_scenario_4
            ;;
        *)
            print_error "Unknown scenario: $scenario"
            exit 1
            ;;
    esac
    print_info "=========================================="
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [scenario_number|all]"
    echo
    echo "Available scenarios:"
    echo "  1 - Register user with customer/role name lookup (recommended)"
    echo "  2 - Register user with direct UUIDs (requires real database IDs)"
    echo "  3 - Register admin user"
    echo "  4 - Register generic user"
    echo "  all - Run all applicable scenarios (skips scenario 2)"
    echo
    echo "Examples:"
    echo "  $0 1          # Run scenario 1 only"
    echo "  $0 all        # Run all scenarios"
    echo
    echo "Environment variables (set these before running):"
    echo "  DB_HOST, DB_USER, DB_PASSWORD, DB_NAME"
    echo "  NATS_URL, NATS_STREAM, NATS_SUBJECT"
    echo "  NATS_USER, NATS_PASSWORD (optional)"
}

# Main execution
main() {
    print_info "User Registration Test Script"
    print_info "============================="
    
    # Check if Python is available
    if ! command_exists python3; then
        print_error "python3 is not installed or not in PATH"
        exit 1
    fi
    
    # Check if the main script exists
    if [ ! -f "register_user.py" ]; then
        print_error "register_user.py not found in current directory"
        exit 1
    fi
    
    # Setup common environment variables
    setup_common_env
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    case $1 in
        1|2|3|4)
            run_scenario $1
            print_success "Scenario $1 completed successfully!"
            ;;
        all)
            print_info "Running all applicable test scenarios..."
            run_scenario 1
            print_info "Pausing between scenarios..."
            sleep 2
            run_scenario 3
            print_info "Pausing between scenarios..."
            sleep 2
            run_scenario 4
            print_success "All scenarios completed successfully!"
            print_warning "Note: Scenario 2 was skipped (requires real database UUIDs)"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            print_error "Invalid option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
