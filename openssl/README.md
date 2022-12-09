# SSL STEP BY STEP

## Generate a certificate authority (CA) cert

```sh
$ openssl req -newkey rsa:4096 -keyform PEM -keyout ca.key -x509 -days 3650 -outform PEM -out ca.cer
```

Result:

```sh
openssl req -newkey rsa:4096 -keyform PEM -keyout ca.key -x509 -days 3650 -outform PEM -out ca.cer
Generating a RSA private key
...........................++++
...++++
writing new private key to 'ca.key'
Enter PEM pass phrase: changeit
Verifying - Enter PEM pass phrase: changeit
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:ES
State or Province Name (full name) [Some-State]:Spain
Locality Name (eg, city) []:Madrid
Organization Name (eg, company) [Internet Widgits Pty Ltd]:localhost
Organizational Unit Name (eg, section) []:Develop 
Common Name (e.g. server FQDN or YOUR name) []:localhost
Email Address []:support@localhost.com
```

## Generate your Server SSL key and certificate

Now that we have our CA cert, we can generate the SSL certificate that will be used by Server.

1. Generate a server private key.

```sh
$ openssl genrsa -out server.key 4096
```

2. Use the server private key to generate a certificate generation request

```sh
$ openssl req -new -key server.key -out server.req -sha256
```

3. Use the certificate generation request and the CA cert to generate the server cert

```sh
$ openssl x509 -req -in server.req -CA ca.cer -CAkey ca.key -set_serial 100 -extensions server -days 1460 -outform PEM -out server.cer -sha256
```

4. Clean up – now that the cert has been created, we no longer need the request

```sh
$ rm server.req
```

## Install the server certificate in Server

## Generate a client SSL certificate

1. Generate a private key for the SSL client
```sh
$ openssl genrsa -out client.key 4096
```

2. Use the client’s private key to generate a cert request
```sh
$ openssl req -new -key client.key -out client.req
```

3. Issue the client certificate using the cert request and the CA cert/key
```sh
$ openssl x509 -req -in client.req -CA ca.cer -CAkey ca.key -set_serial 101 -extensions client -days 365 -outform PEM -out client.cer
```

4. Convert the client certificate and private key to pkcs#12 format for use by browsers
```sh
$ openssl pkcs12 -export -inkey client.key -in client.cer -out client.p12
```

5. Clean up – remove the client private key, client cert and client request files as the pkcs12 has everything needed
```sh
$ rm client.key client.cer client.req
```