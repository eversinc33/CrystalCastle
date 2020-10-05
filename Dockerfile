FROM kalilinux/kali-rolling
RUN mkdir /app
WORKDIR /app
RUN apt update && apt install -y cron golang-go ruby git ruby-dev build-essential libpq-dev iputils-ping 
RUN apt install -y crackmapexec nmap python3 enum4linux smbmap samba
RUN apt install -y python3-pip python2.7 libsasl2-dev libldap2-dev libssl-dev

# ad ldap enum
RUN pip install python-ldap
RUN git clone https://github.com/CroweCybersecurity/ad-ldap-enum && install ad-ldap-enum/ad-ldap-enum.py /usr/bin/ad-ldap-enum
# ffuf
RUN go get -u github.com/ffuf/ffuf
RUN install /root/go/bin/ffuf /bin/ffuf

RUN gem install pg rexml net-ping bcrypt ipaddress sinatra
COPY . /app
COPY worker/cronjob /
ENTRYPOINT ["/app/entrypoint.sh"]
