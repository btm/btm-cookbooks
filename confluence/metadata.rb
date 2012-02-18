maintainer       "Bryan McLellan"
maintainer_email "btm@loftninjas.org"
license          "Apache 2.0"
description      "Installs/Configures confluence"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.2"
depends           "openssl"
depends           "runit"
depends           "java"
depends           "apache2"
recommends        "mysql"

