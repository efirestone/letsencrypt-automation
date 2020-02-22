# letsencrypt-automation

This script updates the certificate on a remote pfSense server via SSH. This is useful with services like LetsEncrypt
which require frequent updates of certificates due to their short expiration dates.

-----------

* There is an attached sed template file for replacing the existing certificate files in pfSense's config.xml.
You must have the certificate uploaded and configed to a name prior to use. By default this script assumes the
certificate is named "LetsEncrypt".

* This script relies on ssh passwordless logins (as root). A quick google will show you how 
to generate keys. id\_ed25519 is the current preferred standard. Most tutorials will suggest
using ssh-copy-id to get the key on the pfSense server, but pfSense requires additional 
configuration with the admin user for persistant upgrades otherwise these keys are lost 
and need to be manually added. This is done by appending the key inside the admin users 
configuration:

- Login to the pfSense Web Dashboard 

- Go to System > User Management > Admin

- Paste the key inside the "Authorized SSH Keys" textbox and save

-----------

The script is configured by setting environment variables before executing it.

PFSENSE\_SVR - (required) Set this to the IP address or host name of the remote pfSense server.
CERT\_FULLCHAIN\_PATH - (required) The path to the fullchain.pem file on the local machine.
CERT\_PRIVKEY\_PATH - (required) The path to the privkey.pem file on the local machine.

PFSENSE\_SSH\_PORT - (optional) If your pfSense server is configured to use a non-standard SSH port
  then that can be configured in this variable.
CERT\_NAME - (optional) The name of the cert to replace as shown in the pfSense Certificate Manager.
  By default "LetsEncrypt" is used.

------------

It's recommended to set up a wrapper script which sets the appropriate variables and then calls this script, like so:

```
#!/bin/bash

export PFSENSE_SVR=pfsense.example.com
export PFSENSE_SSH_PORT=2200

export CERT_NAME=LetsEncrypt
export CERT_FULLCHAIN_PATH=/etc/letsencrypt/example.com/fullchain.pem
export CERT_PRIVKEY_PATH=/etc/letsencrypt/example.com/privkey.pem

/root/Development/letsencrypt-automation/copy_to_pfsense.sh
```

You can then schedule this script using `cron`. On Ubuntu, this can be done by moving the script into /etc/cron.daily 
