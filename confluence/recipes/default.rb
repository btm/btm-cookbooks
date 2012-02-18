#
# Cookbook Name:: confluence
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

unless FileTest.exists?(node[:confluence][:install_path])
  # X11 dependencies for graphic libraries for thumbnailing, pdf export, etc
  %w{libice-dev libsm-dev libx11-dev libxext-dev libxp-dev libxt-dev libxtst-dev}.each do |pack|
    package pack
  end

  remote_file "confluence" do
    path "/tmp/confluence.tar.gz"
    source "http://www.atlassian.com/software/confluence/downloads/binary/confluence-#{node[:confluence][:version]}-std.tar.gz"
  end
  
  bash "untar-confluence" do
    code "(cd /tmp; tar zxvf /tmp/confluence.tar.gz)"
  end
  
  bash "install-confluence" do
    code "mv /tmp/confluence-#{node[:confluence][:version]}-std #{node[:confluence][:install_path]}"
  end
  
  if node[:confluence][:database] == "mysql"
    # These values don't always come from attributes.
    mysql_root_password = node[:mysql][:server_root_password]
    mysql_host = node[:confluence][:database_host]
    #mysql_root_password = search(:node, 'recipes:mysql\:\:server').first.mysql.server_root_password
    #mysql_host = search(:node, 'recipes:mysql\:\:server').first.ipaddress
    #node[:confluence][:database_host] = mysql_host

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
        if !m.list_dbs.include?(node[:confluence][:database_name])
          # Create the database
          Chef::Log.info "Creating mysql database #{node[:confluence][:database_name]}"
          m.query("CREATE DATABASE #{node[:confluence][:database_name]} CHARACTER SET utf8")
        end
    
        # Grant and flush permissions
        Chef::Log.info "Granting access to #{node[:confluence][:database_name]} for #{node[:confluence][:database_user]}"
        m.query("GRANT ALL ON #{node[:confluence][:database_name]}.* TO '#{node[:confluence][:database_user]}'@'#{mysql_grant_host}' IDENTIFIED BY '#{node[:confluence][:database_password]}'")
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
      code "cp /tmp/mysql-connector-java-5.1.13/mysql-connector-java-5.1.13-bin.jar #{node[:confluence][:install_path]}/lib"
    end
  end
end

directory "#{node[:confluence][:install_path]}" do
  recursive true
  owner node[:confluence][:run_user]
  notifies :run, "execute[configure file permissions]", :immediately
end

directory node[:confluence][:home] do
  owner node[:confluence][:run_user]
end

execute "configure file permissions" do
  command "chown -R #{node[:confluence][:run_user]} #{node[:confluence][:install_path]}"
  action :nothing
end

cookbook_file "#{node[:confluence][:install_path]}/bin/startup.sh" do
  owner node[:confluence][:run_user]
  source "startup.sh"
  mode 0755
end
  
template "#{node[:confluence][:install_path]}/conf/server.xml" do
  owner node[:confluence][:run_user]
  source "server.xml.erb"
  mode 0644
end
#  
#template "#{node[:confluence][:install_path]}/atlassian-confluence/WEB-INF/classes/entityengine.xml" do
#  owner node[:confluence][:run_user]
#  source "entityengine.xml.erb"
#  mode 0644
#end
#

template "#{node[:confluence][:install_path]}/confluence/WEB-INF/classes/confluence-init.properties" do
  owner node[:confluence][:run_user]
  source "confluence-init.properties.erb"
  mode 0644
end 

runit_service "confluence"

template "#{node[:apache][:dir]}/sites-available/confluence.conf" do
  source "apache.conf.erb"
  mode 0644
end

apache_site "confluence.conf"
