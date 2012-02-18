#
# Cookbook Name:: jira
# Recipe:: default
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

include_recipe "runit"
include_recipe "java"
include_recipe "apache2"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"
include_recipe "apache2::mod_ssl"

unless FileTest.exists?(node[:jira][:install_path])
  remote_file "jira" do
    path "/tmp/jira.tar.gz"
    source "http://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-#{node[:jira][:version]}-standalone.tar.gz"
  end
  
  bash "untar-jira" do
    code "(cd /tmp; tar zxvf /tmp/jira.tar.gz)"
  end
  
  bash "install-jira" do
    code "mv /tmp/atlassian-jira-#{node[:jira][:version]}-standalone #{node[:jira][:install_path]}"
  end
  
  if node[:jira][:database] == "mysql"
    # These values don't always come from attributes.
    #mysql_root_password = node[:mysql][:server_root_password]
    #mysql_host = node[:jira][:database_host]
    mysql_root_password = search(:node, 'recipes:mysql\:\:server').first.mysql.server_root_password
    mysql_host = search(:node, 'recipes:mysql\:\:server').first.ipaddress
    node[:jira][:database_host] = mysql_host

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
        if !m.list_dbs.include?(node[:jira][:database_name])
          # Create the database
          Chef::Log.info "Creating mysql database #{node[:jira][:database_name]}"
          m.query("CREATE DATABASE #{node[:jira][:database_name]} CHARACTER SET utf8")
        end
    
        # Grant and flush permissions
        Chef::Log.info "Granting access to #{node[:jira][:database_name]} for #{node[:jira][:database_user]}"
        m.query("GRANT ALL ON #{node[:jira][:database_name]}.* TO '#{node[:jira][:database_user]}'@'#{mysql_grant_host}' IDENTIFIED BY '#{node[:jira][:database_password]}'")
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
      code "cp /tmp/mysql-connector-java-5.1.13/mysql-connector-java-5.1.13-bin.jar #{node[:jira][:install_path]}/lib"
    end
  end
end

directory "#{node[:jira][:install_path]}" do
  recursive true
  owner node[:jira][:run_user]
  notifies :run, "execute[configure file permissions]", :immediately
end

directory node[:jira][:home] do
  owner node[:jira][:run_user]
end

execute "configure file permissions" do
  command "chown -R #{node[:jira][:run_user]} #{node[:jira][:install_path]}"
  action :nothing
end

cookbook_file "#{node[:jira][:install_path]}/bin/startup.sh" do
  owner node[:jira][:run_user]
  source "startup.sh"
  mode 0755
end
  
cookbook_file "#{node[:jira][:install_path]}/bin/catalina.sh" do
  owner node[:jira][:run_user]
  source "catalina.sh"
  mode 0755
end

template "#{node[:jira][:install_path]}/conf/server.xml" do
  owner node[:jira][:run_user]
  source "server.xml.erb"
  mode 0644
end
  
template "#{node[:jira][:install_path]}/atlassian-jira/WEB-INF/classes/entityengine.xml" do
  owner node[:jira][:run_user]
  source "entityengine.xml.erb"
  mode 0644
end

template "#{node[:jira][:install_path]}/atlassian-jira/WEB-INF/classes/jira-application.properties" do
  owner node[:jira][:run_user]
  source "jira-application.properties.erb"
  mode 0644
end 

runit_service "jira"

template "#{node[:apache][:dir]}/sites-available/jira.conf" do
  source "apache.conf.erb"
  mode 0644
end

apache_site "jira.conf"
