#
# Cookbook Name:: crowd
# Attributes:: crowd
#
# Copyright 2008-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# The openssl cookbook supplies the secure_password library to generate random passwords
::Chef::Node.send(:include, Opscode::OpenSSL::Password)

default[:crowd][:virtual_host_name]  = "crowd.#{domain}"
default[:crowd][:virtual_host_alias] = "crowd.#{domain}"
# type-version-standalone
default[:crowd][:version]           = "2.1.1"
default[:crowd][:install_path]      = "/srv/crowd"
default[:crowd][:home]              = "/srv/crowd/home"
default[:crowd][:run_user]          = "www-data"
default[:crowd][:database]          = "mysql"
# The mysql cookbook binds to ipaddress by default. Add this to the role.
#  "override_attributes": {
#    "mysql": {
#      "bind_address": "127.0.0.1"
#    }
default[:crowd][:database_host]     = "localhost"
default[:crowd][:database_user]     = "crowd"
set_unless[:crowd][:database_password] = secure_password
default[:crowd][:database_name]     = "crowd"

# Confluence doesn't support OpenJDK http://jira.atlassian.com/browse/CONF-16431
# FIXME: There are some hardcoded paths like JAVA_HOME
set[:java][:install_flavor]    = "sun"

