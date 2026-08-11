#!/bin/bash

# Define Hasura Endpoint and Secret
HASURA_URL="http://hasura:8080/v1/metadata"
HASURA_ADMIN_SECRET="acm_hasura_secret"

# Function to track a table and grant permissions
track_and_permit() {
    local table_name=$1
    local custom_name=$2
    
    echo "Tracking table: $table_name as $custom_name"
    
    # 1. Track Table
    curl -d"{
        \"type\": \"pg_track_table\",
        \"args\": {
            \"source\": \"default\",
            \"schema\": \"public\",
            \"name\": \"$table_name\",
            \"configuration\": {
                \"custom_root_fields\": {
                    \"select\": \"$custom_name\",
                    \"select_by_pk\": \"${custom_name}_by_pk\",
                    \"select_aggregate\": \"${custom_name}_aggregate\"
                }
            }
        }
    }" \
    -H "X-Hasura-Admin-Secret: $HASURA_ADMIN_SECRET" \
    -X POST $HASURA_URL

    # 2. Grant Select Permission to 'admin'
    echo "Granting permissions for: $table_name"
    curl -d"{
        \"type\": \"pg_create_select_permission\",
        \"args\": {
            \"source\": \"default\",
            \"table\": \"$table_name\",
            \"role\": \"admin\",
            \"permission\": {
                \"columns\": \"*\",
                \"filter\": {},
                \"allow_aggregations\": true
            }
        }
    }" \
    -H "X-Hasura-Admin-Secret: $HASURA_ADMIN_SECRET" \
    -X POST $HASURA_URL
    
     # 3. Grant Select Permission to 'viewer' (just in case)
    curl -d"{
        \"type\": \"pg_create_select_permission\",
        \"args\": {
            \"source\": \"default\",
            \"table\": \"$table_name\",
            \"role\": \"viewer\",
            \"permission\": {
                \"columns\": \"*\",
                \"filter\": {},
                \"allow_aggregations\": true
            }
        }
    }" \
    -H "X-Hasura-Admin-Secret: $HASURA_ADMIN_SECRET" \
    -X POST $HASURA_URL
}

# Track tables matching frontend expectations
track_and_permit "acm_alerts" "fraud_alerts"
track_and_permit "acm_call_records" "call_logs"
track_and_permit "acm_trunks" "gateways"
track_and_permit "acm_users" "users"
track_and_permit "acm_blocked_numbers" "blocked_numbers"
track_and_permit "acm_whitelisted_numbers" "whitelisted_numbers"

echo "Metadata and Permissions update complete."
