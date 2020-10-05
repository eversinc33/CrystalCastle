#!/bin/python3
import sys, ssl, OpenSSL

def enum_subdomains(domain, port):
    cert = ssl.get_server_certificate((domain, port))
    x509 = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, cert)
    subdomains = []
    for i in range(0, x509.get_extension_count()):
        ext = x509.get_extension(i)
        if "subjectAltName" in str(ext.get_short_name()):
            content = ext.__str__()
            for subdomain in content.split(","):
                subdomains.append(subdomain.strip()[4:])
    return subdomains

if __name__ == '__main__':
    print(sys.argv)
    domain = sys.argv[0]
    port = sys.argv[1]
    for subdomain in enum_subdomains(domain, port):
        print(subdomain)