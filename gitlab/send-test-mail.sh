#!/usr/bin/env bash

# Script to read GitLab SMTP configuration and send a test email
# Usage: ./send-test-mail.sh <recipient_email>

set -e

# Email validation function
validate_email() {
  local email="$1"
  # Basic email validation pattern
  local email_pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
  
  if [[ "$email" =~ $email_pattern ]]; then
    return 0  # Valid email
  else
    return 1  # Invalid email
  fi
}

# Check if recipient email is provided
if [ $# -lt 1 ]; then
  echo "Error: Recipient email is required"
  echo ""
  echo "Usage:"
  echo "  $0 <recipient_email>"
  echo ""
  echo "Example:"
  echo "  $0 user@example.com"
  exit 1
fi

RECIPIENT_EMAIL="$1"

# Validate email format
if ! validate_email "$RECIPIENT_EMAIL"; then
  echo "Error: '$RECIPIENT_EMAIL' is not a valid email address"
  echo ""
  echo "Usage:"
  echo "  $0 <recipient_email>"
  echo ""
  echo "Example:"
  echo "  $0 user@example.com"
  exit 1
fi

CONTAINER_NAME="gitlab"

echo "Reading GitLab SMTP configuration from container: $CONTAINER_NAME"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: Container '$CONTAINER_NAME' is not running"
  exit 1
fi

# Extract GITLAB_OMNIBUS_CONFIG environment variable from the container
echo "Extracting configuration..."
CONFIG=$(docker exec $CONTAINER_NAME bash -c 'echo -e "$GITLAB_OMNIBUS_CONFIG"')

if [ -z "$CONFIG" ]; then
  echo "Error: Failed to extract GITLAB_OMNIBUS_CONFIG from container"
  exit 1
fi

# Extract SMTP configuration into separate variables
echo "Parsing SMTP configuration..."
SMTP_ENABLED=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_enable'\].*" | sed "s/gitlab_rails\['smtp_enable'\] = //")
SMTP_ADDRESS=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_address'\].*" | sed "s/gitlab_rails\['smtp_address'\] = //" | tr -d "'" | tr -d '"')
SMTP_PORT=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_port'\].*" | sed "s/gitlab_rails\['smtp_port'\] = //")
SMTP_USER=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_user_name'\].*" | sed "s/gitlab_rails\['smtp_user_name'\] = //" | tr -d "'" | tr -d '"')
SMTP_PASS=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_password'\].*" | sed "s/gitlab_rails\['smtp_password'\] = //" | tr -d "'" | tr -d '"')
SMTP_DOMAIN=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_domain'\].*" | sed "s/gitlab_rails\['smtp_domain'\] = //" | tr -d "'" | tr -d '"')
SMTP_AUTH=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_authentication'\].*" | sed "s/gitlab_rails\['smtp_authentication'\] = //" | tr -d "'" | tr -d '"')
SMTP_STARTTLS=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_enable_starttls_auto'\].*" | sed "s/gitlab_rails\['smtp_enable_starttls_auto'\] = //")
SMTP_TLS=$(echo "$CONFIG" | grep -o "gitlab_rails\['smtp_tls'\].*" | sed "s/gitlab_rails\['smtp_tls'\] = //")
SMTP_FROM=$(echo "$CONFIG" | grep -o "gitlab_rails\['gitlab_email_from'\].*" | sed "s/gitlab_rails\['gitlab_email_from'\] = //" | tr -d "'" | tr -d '"')
SMTP_REPLY_TO=$(echo "$CONFIG" | grep -o "gitlab_rails\['gitlab_email_reply_to'\].*" | sed "s/gitlab_rails\['gitlab_email_reply_to'\] = //" | tr -d "'" | tr -d '"')

# Display extracted SMTP configuration with simple formatting
echo ""
echo "================================================================="
echo "                   GITLAB SMTP CONFIGURATION                      "
echo "================================================================="
printf "%-25s | %-40s\n" "Parameter" "Value"
echo "--------------------------|--------------------------------------"
printf "%-25s | %-40s\n" "SMTP Enabled" "${SMTP_ENABLED:-Not configured}"
printf "%-25s | %-40s\n" "SMTP Address" "${SMTP_ADDRESS:-Not configured}"
printf "%-25s | %-40s\n" "SMTP Port" "${SMTP_PORT:-Not configured}"
printf "%-25s | %-40s\n" "SMTP User" "${SMTP_USER:-Not configured}"
if [ -n "$SMTP_PASS" ]; then
  printf "%-25s | %-40s\n" "SMTP Password" "${SMTP_PASS:0:3}*** (masked)"
else
  printf "%-25s | %-40s\n" "SMTP Password" "Not configured"
fi
printf "%-25s | %-40s\n" "SMTP Domain" "${SMTP_DOMAIN:-Not configured}"
printf "%-25s | %-40s\n" "SMTP Authentication" "${SMTP_AUTH:-Not configured}"
printf "%-25s | %-40s\n" "SMTP StartTLS Auto" "${SMTP_STARTTLS:-Not configured}"
printf "%-25s | %-40s\n" "SMTP TLS" "${SMTP_TLS:-Not configured}"
printf "%-25s | %-40s\n" "Email From" "${SMTP_FROM:-Not configured}"
printf "%-25s | %-40s\n" "Email Reply-To" "${SMTP_REPLY_TO:-Not configured}"
printf "%-25s | %-40s\n" "Recipient Email" "${RECIPIENT_EMAIL}"
echo "================================================================="

# Test connection function
test_smtp_connection() {
  echo ""
  echo "================================================================="
  echo "                    TESTING SMTP CONNECTION                       "
  echo "================================================================="
  
  # Only attempt test if SMTP appears to be configured
  if [ -z "$SMTP_ADDRESS" ] || [ -z "$SMTP_PORT" ]; then
    echo "❌ Cannot test SMTP connection: Address or port not configured"
    return 1
  fi
  
  echo "🔄 Testing connection to SMTP server: $SMTP_ADDRESS:$SMTP_PORT..."
  
  # First try a simple connection test with netcat
  echo "Step 1: Testing basic network connectivity..."
  if nc -z -w5 "$SMTP_ADDRESS" "$SMTP_PORT" 2>/dev/null; then
    echo "✅ Basic network connectivity successful"
  else
    echo "❌ Failed to establish basic network connection to $SMTP_ADDRESS:$SMTP_PORT"
    
    # Try DNS resolution to check if the server address is valid
    echo "Checking DNS resolution for $SMTP_ADDRESS..."
    if host "$SMTP_ADDRESS" > /dev/null 2>&1; then
      echo "✅ DNS resolution successful for $SMTP_ADDRESS"
      
      # Check if the gitlab container has network access
      echo "Checking if GitLab container has network access..."
      if docker exec $CONTAINER_NAME ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
        echo "✅ GitLab container has network access"
        echo "❌ The SMTP server may be blocking connections or firewall rules may be preventing access"
      else
        echo "❌ GitLab container doesn't have network access"
      fi
    else
      echo "❌ Failed to resolve DNS for $SMTP_ADDRESS. The server name might be incorrect."
    fi
    
    return 1
  fi

  echo "✅ Connection to SMTP server successful (basic network connectivity)"
  echo "================================================================="
  return 0
}

# Send test email function
send_test_email() {
  echo ""
  echo "================================================================="
  echo "                      SENDING TEST EMAIL                          "
  echo "================================================================="
  echo "From: $SMTP_FROM"
  echo "To: $RECIPIENT_EMAIL"
  echo "Subject: GitLab Test Email"
  echo ""
  
  echo "🔄 Sending test email through GitLab's Rails console..."
  EMAIL_COMMAND="Notify.test_email('$RECIPIENT_EMAIL', 'GitLab Test Email', 'This is a test email sent from GitLab via $SMTP_ADDRESS:$SMTP_PORT').deliver_now"
  
  # Execute the command and capture the output
  EMAIL_RESULT=$(docker exec $CONTAINER_NAME gitlab-rails runner "$EMAIL_COMMAND" 2>&1)
  EMAIL_STATUS=$?
  
  echo ""
  echo "Result of test email attempt:"
  echo "$EMAIL_RESULT"
  
  if [ $EMAIL_STATUS -eq 0 ] && [[ "$EMAIL_RESULT" != *"error"* && "$EMAIL_RESULT" != *"Error"* && "$EMAIL_RESULT" != *"exception"* && "$EMAIL_RESULT" != *"Exception"* ]]; then
    echo ""
    echo "✅ Test email appears to have been sent successfully!"
    echo "   Please check the inbox of $RECIPIENT_EMAIL for the test email."
  else
    echo ""
    echo "❌ Failed to send test email. Check the output above for error details."
  fi
  
  echo "================================================================="
}

# Always test SMTP connection
test_smtp_connection

# Always send test email since recipient is provided
send_test_email