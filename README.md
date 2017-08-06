# CloudflareUpdate
This is a small script that updates Cloudflare DNS-Records to the public ip of the system.

## Requirements
The following Perl-packages are required:
* JSON
* LWP::Simple
* WWW::Curl
* Data::Dumper

Furthermore, you need Curl on your system.

## Getting started
Open the file CloudflareUpdate.pl and fill in the information of your account.
Test the script by running ./CloudflareUpdate.pl

## Running this script automatically

I've placed that script in /opt/CloudflareUpdate/CloudflareUpdate.pl

Add the following line to the crontab file by running `crontab -e`:
```
*/5 * * * * /opt/CloudflareUpdate/CloudflareUpdate.pl > /var/log/CloudflareUpdate.log
```

This will run the script every five minutes.
