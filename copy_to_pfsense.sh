#!/bin/bash

if [ -z "$PFSENSE_SVR" ]; then echo "PFSENSE_SVR must be set to the address of the pfSense server"; exit 1; fi
if [ -z "$CERT_FULLCHAIN_PATH" ]; then echo "CERT_FULLCHAIN_PATH must be set to the path to the fullchain.pem file"; exit 1; fi
if [ -z "$CERT_PRIVKEY_PATH" ]; then echo "CERT_PRIVKEY_PATH must be set to the path to the privkey.pem file"; exit 1; fi

command -v base64 >/dev/null 2>&1 || { echo >&2 "This script requires that the base64 utility is installed."; exit 1; }

SCRIPT_DIR="${BASH_SOURCE%/*}"

# Set this variable to match the name of the certificate to be replaced as shown in pfSense's Certificate Manager.
# By default we'll use "LetsEncrypt"
CERT_NAME=${CERT_NAME-LetsEncrypt}

# The default SSH port can be overridden by setting this variable.
PFSENSE_SSH_PORT=${PFSENSE_SSH_PORT-22}

ENCRT=$(cat $CERT_FULLCHAIN_PATH | base64 -w 0)
ENKEY=$(cat $CERT_PRIVKEY_PATH | base64  -w 0)

# Replace the placeholder string in the pattern template with certificate information.
# awk is used because of the escape characters aren't passed via sed.

PATTERN_TEMPLATE_PATH="$SCRIPT_DIR/pattern.template"
PATTERN_PATH=/tmp/pfsense_update/pattern.sub
mkdir -p $(dirname $PATTERN_PATH)
cat $PATTERN_TEMPLATE_PATH | awk '$1=$1' FS="NAMEPLACEHOLDER" OFS="$CERT_NAME" | awk '$1=$1' FS="CRTPLACEHOLDER" OFS="$ENCRT"  | awk '$1=$1' FS="KEYPLACEHOLDER" OFS="$ENKEY" > $PATTERN_PATH

# scp the pattern file to the pfsense system
scp -P $PFSENSE_SSH_PORT $PATTERN_PATH $PFSENSE_SVR:/tmp/
rm -rf $(dirname $PATTERN_PATH)

# execute sed replace against the config.xml and reload the configuration

ssh $PFSENSE_SVR -p $PFSENSE_SSH_PORT 'cp /conf/config.xml /tmp/config.xml && sed -f /tmp/pattern.sub < /tmp/config.xml > /conf/config.xml && rm /tmp/config.cache && rm /tmp/pattern.sub && /etc/rc.restart_webgui'

