#
# Cookbook Name:: confluence
# Attributes:: confluence
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

default[:confluence][:virtual_host_name]  = "confluence.#{domain}"
default[:confluence][:virtual_host_alias] = "confluence.#{domain}"
# type-version-standalone
default[:confluence][:version]           = "3.4.8"
default[:confluence][:install_path]      = "/srv/confluence"
default[:confluence][:home]              = "/srv/confluence/home"
default[:confluence][:run_user]          = "www-data"
default[:confluence][:server_port]       = "8001"
default[:confluence][:connector_port]    = "8081"
default[:confluence][:database]          = "mysql"
# The mysql cookbook binds to ipaddress by default. Add this to the role.
#  "override_attributes": {
#    "mysql": {
#      "bind_address": "127.0.0.1"
#    }
default[:confluence][:database_host]     = "localhost"
default[:confluence][:database_user]     = "confluence"
set_unless[:confluence][:database_password] = secure_password
default[:confluence][:database_name]     = "confluence"

# Confluence doesn't support OpenJDK http://jira.atlassian.com/browse/CONF-16431
# FIXME: There are some hardcoded paths like JAVA_HOME
set[:java][:install_flavor]    = "sun"

