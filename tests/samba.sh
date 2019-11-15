#!/bin/bash -eux

set -xueo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get -y update

apt-get -y install \
    acl \
    attr \
    autoconf \
    binutils \
    bison \
    build-essential \
    debhelper \
    dnsutils \
    docbook-xml \
    docbook-xsl \
    flex \
    gdb \
    krb5-user \
    libacl1-dev \
    libaio-dev \
    libarchive-dev \
    libattr1-dev \
    libblkid-dev \
    libbsd-dev \
    libcap-dev \
    libcups2-dev \
    libgnutls28-dev \
    libgpgme-dev \
    libjansson-dev \
    libjson-perl \
    libldap2-dev \
    liblmdb-dev \
    libncurses5-dev \
    libpam0g-dev \
    libparse-yapp-perl \
    libpopt-dev \
    libreadline-dev \
    lmdb-utils \
    nettle-dev \
    perl \
    perl-modules \
    pkg-config \
    python-all-dev \
    python-crypto \
    python-dbg \
    python-dev \
    python-dnspython \
    python-markdown \
    python3-dev \
    python3-dnspython \
    python3-markdown \
    python3-dbg \
    xsltproc \
    zlib1g-dev

apt-get -y autoremove
apt-get -y autoclean
apt-get -y clean

wget --no-check-certificate https://download.samba.org/pub/samba/stable/samba-4.11.2.tar.gz
tar -zxf samba-4.11.2.tar.gz
cd samba-4.11.2/
./configure \
    --with-winbind \
    --without-systemd \
    --with-ntvfs-fileserver \
    --with-configdir=/etc/samba/ \
    --with-privatedir=/var/lib/samba/private \

make -j 4 && make install

export PATH=/usr/local/samba/bin/:/usr/local/samba/sbin/:$PATH

# Samba must not be running during the provisioning
service smbd stop
service nmbd stop 
service winbind stop
service samba-ad-dc stop

# Domain provision
rm -fr /etc/samba/smb.conf
samba-tool domain provision --realm=LOCAL.DOMAIN --domain=LOCAL --server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass='4dm1n_s3cr36_v3ry_c0mpl3x' --use-rfc2307 --use-ntvfs -d 1

# Start samba-ad-dc service only
rm -fr /etc/systemd/system/samba-ad-dc.service
service samba-ad-dc start

# Add users and groups
samba-tool user create user1 --use-username-as-cn --surname=Test1 --given-name=User1 --random-password
samba-tool user create user2 --use-username-as-cn --surname=Test2 --given-name=User2 --random-password
samba-tool user create user3 --use-username-as-cn --surname=Test3 --given-name=User3 --random-password
samba-tool user create user4 --use-username-as-cn --surname=Test4 --given-name=User4 --random-password
samba-tool user create user5 --use-username-as-cn --surname=Test5 --given-name=User5 --random-password

# Add some groups
samba-tool group add IT
samba-tool group add Admins
samba-tool group add Devs
samba-tool group add DevOps

# Create members
$(which samba-tool) group addmembers IT Admins,Devs,DevOps,user1
$(which samba-tool) group addmembers Admins user2,user3
$(which samba-tool) group addmembers Devs user4
$(which samba-tool) group addmembers DevOps user5

# Add AD certificate
echo -n | openssl s_client -connect localhost:636 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > /usr/local/share/ca-certificates/ad.crt
update-ca-certificates

# Add cache to nsswitch
cat > '/etc/nsswitch.conf' << EOF
passwd:         files cache
group:          files cache
shadow:         files cache
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF
