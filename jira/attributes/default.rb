#
# Cookbook Name:: jira
# Attributes:: jira
#
# Copyright 2008-2009, Opscode, Inc.
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

default[:jira][:virtual_host_name]  = "jira.#{domain}"
default[:jira][:virtual_host_alias] = "jira.#{domain}"
# type-version-standalone
default[:jira][:version]           = "enterprise-4.2.4-b591"
default[:jira][:install_path]      = "/srv/jira"
default[:jira][:home]              = "/srv/jira/home"
default[:jira][:run_user]          = "www-data"
default[:jira][:database]          = "mysql"
# The mysql cookbook binds to ipaddress by default. Add this to the role.
#  "override_attributes": {
#    "mysql": {
#      "bind_address": "127.0.0.1"
#    }
default[:jira][:database_host]     = "localhost"
default[:jira][:database_user]     = "jira"
set_unless[:jira][:database_password] = secure_password
default[:jira][:database_name]     = "jiradb"

# FIXME: There are some hardcoded paths like JAVA_HOME
default[:java][:install_flavor]    = "sun"

