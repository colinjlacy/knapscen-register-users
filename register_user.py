#!/usr/bin/env python3
"""
User Registration Script

This script reads user information from environment variables, registers the user
in the MySQL database, and publishes an event to NATS JetStream.

Required Environment Variables:
- USER_NAME: Full name of the user
- USER_EMAIL: Email address of the user
- CUSTOMER_ID: UUID of the customer (or use CUSTOMER_NAME to lookup)
- ROLE_ID: UUID of the role (or use ROLE_NAME to lookup)

Database Connection (required):
- DB_HOST: Database hostname
- DB_PORT: Database port (default: 3306)
- DB_USER: Database username
- DB_PASSWORD: Database password
- DB_NAME: Database name

NATS Connection (required):
- NATS_SERVER: NATS server URL
- NATS_STREAM: JetStream stream name
- NATS_SUBJECT: Subject to publish to
- NATS_USER: NATS username
- NATS_PASSWORD: NATS password

Optional lookup variables (use instead of IDs):
- CUSTOMER_NAME: Name of the corporate customer (will lookup ID)
- ROLE_NAME: Name of the role (will lookup ID)
"""

import os
import sys
import json
import logging
import asyncio
from typing import Optional, Dict, Any
from dataclasses import dataclass

import pymysql
import nats
from nats.js import JetStreamContext


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class UserInfo:
    """Data class for user information"""
    name: str
    email: str
    customer_id: str
    role_id: str


@dataclass
class DatabaseConfig:
    """Data class for database configuration"""
    host: str
    port: int
    user: str
    password: str
    database: str


@dataclass
class NATSConfig:
    """Data class for NATS configuration"""
    server: str
    stream: str
    subject: str
    user: str
    password: str

class UserRegistrationError(Exception):
    """Custom exception for user registration errors"""
    pass


def get_env_var(name: str, required: bool = True, default: str = None) -> Optional[str]:
    """Get environment variable with validation"""
    value = os.getenv(name, default)
    if required and not value:
        raise UserRegistrationError(f"Required environment variable {name} is not set")
    return value


def get_database_config() -> DatabaseConfig:
    """Extract database configuration from environment variables"""
    return DatabaseConfig(
        host=get_env_var('DB_HOST'),
        port=int(get_env_var('DB_PORT', default='3306')),
        user=get_env_var('DB_USER'),
        password=get_env_var('DB_PASSWORD'),
        database=get_env_var('DB_NAME')
    )


def get_nats_config() -> NATSConfig:
    """Extract NATS configuration from environment variables"""
    return NATSConfig(
        server=get_env_var('NATS_SERVER'),
        stream=get_env_var('NATS_STREAM'),
        subject=get_env_var('NATS_SUBJECT'),
        user=get_env_var('NATS_USER'),
        password=get_env_var('NATS_PASSWORD')
    )


def lookup_customer_id(connection, customer_name: str) -> str:
    """Lookup customer ID by name"""
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT id FROM corporate_customers WHERE name = %s",
            (customer_name,)
        )
        result = cursor.fetchone()
        if not result:
            raise UserRegistrationError(f"Customer '{customer_name}' not found")
        return result[0]


def lookup_role_id(connection, role_name: str) -> str:
    """Lookup role ID by name"""
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT id FROM user_roles WHERE role_name = %s",
            (role_name,)
        )
        result = cursor.fetchone()
        if not result:
            raise UserRegistrationError(f"Role '{role_name}' not found")
        return result[0]


def get_user_info(connection) -> UserInfo:
    """Extract and validate user information from environment variables"""
    name = get_env_var('USER_NAME')
    email = get_env_var('USER_EMAIL')
    
    # Get customer ID (either directly or via lookup)
    customer_id = get_env_var('CUSTOMER_ID', required=False)
    customer_name = get_env_var('CUSTOMER_NAME', required=False)
    
    if not customer_id and not customer_name:
        raise UserRegistrationError("Either CUSTOMER_ID or CUSTOMER_NAME must be provided")
    
    if customer_name and not customer_id:
        customer_id = lookup_customer_id(connection, customer_name)
    
    # Get role ID (either directly or via lookup)
    role_id = get_env_var('ROLE_ID', required=False)
    role_name = get_env_var('ROLE_NAME', required=False)
    
    if not role_id and not role_name:
        raise UserRegistrationError("Either ROLE_ID or ROLE_NAME must be provided")
    
    if role_name and not role_id:
        role_id = lookup_role_id(connection, role_name)
    
    return UserInfo(
        name=name,
        email=email,
        customer_id=customer_id,
        role_id=role_id
    )


def insert_user(connection, user_info: UserInfo) -> str:
    """Insert user into database and return the generated user ID"""
    try:
        with connection.cursor() as cursor:
            # Insert the user (ID will be auto-generated)
            insert_query = """
                INSERT INTO users (customer_id, role_id, name, email)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(insert_query, (
                user_info.customer_id,
                user_info.role_id,
                user_info.name,
                user_info.email
            ))
            
            # Get the generated user ID
            cursor.execute("SELECT LAST_INSERT_ID()")
            # For UUID primary keys, we need to get the actual UUID
            cursor.execute(
                "SELECT id FROM users WHERE email = %s ORDER BY created_at DESC LIMIT 1",
                (user_info.email,)
            )
            result = cursor.fetchone()
            user_id = result[0]
            
            connection.commit()
            logger.info(f"Successfully inserted user {user_info.name} with ID {user_id}")
            return user_id
            
    except pymysql.IntegrityError as e:
        if "Duplicate entry" in str(e) and "email" in str(e):
            raise UserRegistrationError(f"User with email {user_info.email} already exists")
        raise UserRegistrationError(f"Database integrity error: {e}")
    except Exception as e:
        connection.rollback()
        raise UserRegistrationError(f"Failed to insert user: {e}")


def prepare_event_data() -> Dict[str, Any]:
    """Prepare event data from environment variables, excluding DB and NATS config"""
    # Include user-related environment variables
    event_data = {}
    
    user_vars = [
        'USER_NAME', 'USER_EMAIL', 'CUSTOMER_ID', 'CUSTOMER_NAME', 
        'ROLE_ID', 'ROLE_NAME'
    ]
    
    for var in user_vars:
        value = os.getenv(var)
        if value:
            event_data[var.lower()] = value
        
    return event_data


async def publish_event(nats_config: NATSConfig, event_data: Dict[str, Any], user_id: str):
    """Publish user registration event to NATS JetStream"""
    try:
        # Connect to NATS with optional authentication
        connect_options = {"servers": [nats_config.server]}
        connect_options["user"] = nats_config.user
        connect_options["password"] = nats_config.password
            
        nc = await nats.connect(**connect_options)
        js = nc.jetstream()
        
        # Prepare the event payload
        event_payload = {
            'event_type': 'user_registered',
            'user_id': user_id,
            'timestamp': str(asyncio.get_event_loop().time()),
            'data': event_data
        }
        
        # Publish to JetStream
        await js.publish(
            subject=nats_config.subject,
            payload=json.dumps(event_payload).encode('utf-8')
        )
        
        logger.info(f"Successfully published event to {nats_config.subject}")
        
        # Close connection
        await nc.close()
        
    except Exception as e:
        raise UserRegistrationError(f"Failed to publish NATS event: {e}")


async def main():
    """Main function"""
    try:
        logger.info("Starting user registration process...")
        
        # Get configuration
        db_config = get_database_config()
        nats_config = get_nats_config()
        
        # Connect to database
        logger.info("Connecting to database...")
        connection = pymysql.connect(
            host=db_config.host,
            port=db_config.port,
            user=db_config.user,
            password=db_config.password,
            database=db_config.database,
            charset='utf8mb4'
        )
        
        try:
            # Get user information
            logger.info("Extracting user information...")
            user_info = get_user_info(connection)
            
            # Insert user into database
            logger.info("Registering user in database...")
            user_id = insert_user(connection, user_info)
            
            # Prepare event data
            logger.info("Preparing event data...")
            event_data = prepare_event_data()
            
            # Publish event to NATS
            logger.info("Publishing event to NATS JetStream...")
            await publish_event(nats_config, event_data, user_id)
            
            logger.info("User registration completed successfully!")
            print(f"User registered successfully with ID: {user_id}")
            
        finally:
            connection.close()
            
    except UserRegistrationError as e:
        logger.error(f"Registration error: {e}")
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
