def set_nginx_config name
  file = File.open('/opt/nginx/conf/nginx.conf', 'r+') # r+ -> read/write from begginin of a file
  file.seek(-2, IO::SEEK_END)
  file.write tenant_config(name)
  file.close
end

def tenant_config name
  ["",
   "\tserver {",
   "\t\tlisten 8080;",
   "\t\tserver_name #{name}.dobri.robopartans.com;",
   "\t\tpassenger_enabled on;",
   "\t\troot /var/www-data/#{name}/public;",
   "\t}",
   "}"].join "\n"
end

def database_config database
  ["production:",
   "  adapter: mysql2",
   "  username: root",
   "  password: robopart",
   "  database: #{database}",
   "  pool: 5",
   "  timeout: 5000"].join "\n"
end

def create_db
  `RAILS_ENV=production bundle exec rake db:create > /var/www-data/dbc.log`
  `RAILS_ENV=production bundle exec rake db:migrate > /var/www-data/dbm.log`
end

def figaro_configs
  'SECRET_KEY: ' + `rake secret`
end

name = ARGV[0]

Dir.chdir('/var/www-data') do
  `git clone fllcasts #{name}`
  Dir.chdir("/var/www-data/#{name}") do
    File.open("/var/www-data/#{name}/config/database.yml", "w") do |file| # w -> overwrite
      file.write database_config(name)
    end
    File.open("/var/www-data/#{name}/config/application.yml", "w") do |file| # w -> overwrite
      file.write figaro_configs
    end
    create_db
  end
end
File.symlink("/var/www-data/#{name}/public", "/var/www-data/projo/public/#{name}")
set_nginx_config(name)
`/opt/nginx/sbin/nginx -s reload`