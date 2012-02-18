#
# Cookbook Name:: crowd
# Recipe:: default
#
# Copyright 2011, Opscode, Inc.
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

include_recipe "runit"
include_recipe "java"
include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"
include_recipe "apache2::mod_ssl"

unless FileTest.exists?(node[:crowd][:install_path])
  remote_file "crowd" do
    path "/tmp/crowd.tar.gz"
    source "http://www.atlassian.com/software/crowd/downloads/binary/atlassian-crowd-#{node[:crowd][:version]}.tar.gz"
  end
  
  bash "untar-crowd" do
    code "(cd /tmp; tar zxvf /tmp/crowd.tar.gz)"
  end
  
  bash "install-crowd" do
    code "mv /tmp/atlassian-crowd-#{node[:crowd][:version]} #{node[:crowd][:install_path]}"
  end
  
  if node[:crowd][:database] == "mysql"
    # These values don't always come from attributes.
    mysql_root_password = node[:mysql][:server_root_password]
    mysql_host = node[:crowd][:database_host]
    #mysql_root_password = search(:node, 'recipes:mysql\:\:server').first.mysql.server_root_password
    #mysql_host = search(:node, 'recipes:mysql\:\:server').first.ipaddress
    #node[:crowd][:database_host] = mysql_host

    # mysql should be running
    if mysql_host == "localhost"
      include_recipe "mysql::server"

      # Assume a local mysql server isn't clustered and should be running
      service "mysql" do
        action :start
      end
      mysql_grant_host = mysql_host
    else
      mysql_grant_host = node[:ipaddress]
    end
    
    # Configure the ability to access mysql from the cookbook
    package "libmysql-ruby"

    ruby_block "Create database + execute grants" do
      block do 
        require 'rubygems'
        Gem.clear_paths
        require 'mysql'
    
        m = Mysql.new(mysql_host, "root", mysql_root_password)
        if !m.list_dbs.include?(node[:crowd][:database_name])
          # Create the database
          Chef::Log.info "Creating mysql database #{node[:crowd][:database_name]}"
          m.query("CREATE DATABASE #{node[:crowd][:database_name]} CHARACTER SET utf8")
        end
    
        # Grant and flush permissions
        Chef::Log.info "Granting access to #{node[:crowd][:database_name]} for #{node[:crowd][:database_user]}"
        m.query("GRANT ALL ON #{node[:crowd][:database_name]}.* TO '#{node[:crowd][:database_user]}'@'#{mysql_grant_host}' IDENTIFIED BY '#{node[:crowd][:database_password]}'")
        m.reload
      end
    end

    remote_file "mysql-connector" do
      path "/tmp/mysql-connector.tar.gz"
      source "http://downloads.mysql.com/archives/mysql-connector-java-5.1/mysql-connector-java-5.1.13.tar.gz"
    end
  
    bash "untar-mysql-connector" do
      code "(cd /tmp; tar zxvf /tmp/mysql-connector.tar.gz)"
    end
  
    bash "install-mysql-connector" do
      code "cp /tmp/mysql-connector-java-5.1.13/mysql-connector-java-5.1.13-bin.jar #{node[:crowd][:install_path]}/apache-tomcat/lib/"
    end
  end
end

directory "#{node[:crowd][:install_path]}" do
  recursive true
  owner node[:crowd][:run_user]
  notifies :run, "execute[configure file permissions]", :immediately
end

directory node[:crowd][:home] do
  owner node[:crowd][:run_user]
end

execute "configure file permissions" do
  command "chown -R #{node[:crowd][:run_user]} #{node[:crowd][:install_path]}"
  action :nothing
end

cookbook_file "#{node[:crowd][:install_path]}/apache-tomcat/bin/startup.sh" do
  owner node[:crowd][:run_user]
  source "startup.sh"
  mode 0755
end
  
template "#{node[:crowd][:install_path]}/crowd-webapp/WEB-INF/classes/crowd-init.properties" do
  owner node[:crowd][:run_user]
  source "crowd-init.properties.erb"
  mode 0644
end 

runit_service "crowd"

template "#{node[:apache][:dir]}/sites-available/crowd.conf" do
  source "apache.conf.erb"
  mode 0644
end

apache_site "crowd.conf"
