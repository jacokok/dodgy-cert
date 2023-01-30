# dodgy-cert
This will add root certificate of specified website to ca trust (Dodgy is in the repo name for a reason)

## To run script

Script accepts two arguments. BaseHost and Port

Make sure you run this script in directory where you have access to create temp files.

```bash
curl -sL https://raw.githubusercontent.com/jacokok/dodgy-cert/main/dodgy-cert.sh | bash -s google.com 443
```
