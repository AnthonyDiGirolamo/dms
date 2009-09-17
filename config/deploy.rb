# require 'mongrel_cluster/recipes'

# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.

set :application, "dms"
set :scm, :git
set :repository, "/home/adigiro/dms.git"

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

role :web, "129.219.33.6"
role :app, "129.219.33.6"
role :db,  "129.219.33.6", :primary => true

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
set :deploy_to, "/var/www/rails/#{application}" # defaults to "/u/apps/#{application}"
set :use_sudo, false
set :group_writable, false
set :user, "adigiro"               					# defaults to the currently logged in user
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"
ssh_options[:port] = 27710
set :runner, "adigiro"

# set :scm, :darcs               # defaults to :subversion
# set :svn, "/path/to/svn"       # defaults to searching the PATH
# set :darcs, "/path/to/darcs"   # defaults to searching the PATH
# set :cvs, "/path/to/cvs"       # defaults to searching the PATH
# set :gateway, "gate.host.com"  # default to no gateway

# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)
# ssh_options[:port] = 25

# =============================================================================
# TASKS
# =============================================================================
# Define tasks that run on all (or only some) of the machines. You can specify
# a role (or set of roles) that each task should be executed on. You can also
# narrow the set of servers to a subset of a role by specifying options, which
# must match the options given for the servers to select (like :primary => true)

task :set_permissions do
	  donothing = true
end

# desc <<DESC
# An imaginary backup task. (Execute the 'show_tasks' task to display all
# available tasks.)
# DESC
# task :backup, :roles => :db, :only => { :primary => true } do
#   # the on_rollback handler is only executed if this task is executed within
#   # a transaction (see below), AND it or a subsequent task fails.
#   on_rollback { delete "/tmp/dump.sql" }
#
#   run "mysqldump -u theuser -p thedatabase > /tmp/dump.sql" do |ch, stream, out|
#     ch.send_data "thepassword\n" if out =~ /^Enter password:/
#   end
# end

# Tasks may take advantage of several different helper methods to interact
# with the remote server(s). These are:
#
# * run(command, options={}, &block): execute the given command on all servers
#   associated with the current task, in parallel. The block, if given, should
#   accept three parameters: the communication channel, a symbol identifying the
#   type of stream (:err or :out), and the data. The block is invoked for all
#   output from the command, allowing you to inspect output and act
#   accordingly.
# * sudo(command, options={}, &block): same as run, but it executes the command
#   via sudo.
# * delete(path, options={}): deletes the given file or directory from all
#   associated servers. If :recursive => true is given in the options, the
#   delete uses "rm -rf" instead of "rm -f".
# * put(buffer, path, options={}): creates or overwrites a file at "path" on
#   all associated servers, populating it with the contents of "buffer". You
#   can specify :mode as an integer value, which will be used to set the mode
#   on the file.
# * render(template, options={}) or render(options={}): renders the given
#   template and returns a string. Alternatively, if the :template key is given,
#   it will be treated as the contents of the template to render. Any other keys
#   are treated as local variables, which are made available to the (ERb)
#   template.

# desc "Demonstrates the various helper methods available to recipes."
# task :helper_demo do
#   # "setup" is a standard task which sets up the directory structure on the
#   # remote servers. It is a good idea to run the "setup" task at least once
#   # at the beginning of your app's lifetime (it is non-destructive).
#   setup
#
#   buffer = render("maintenance.rhtml", :deadline => ENV['UNTIL'])
#   put buffer, "#{shared_path}/system/maintenance.html", :mode => 0644
#   sudo "killall -USR1 dispatch.fcgi"
#   run "#{release_path}/script/spin"
#   delete "#{shared_path}/system/maintenance.html"
# end

# You can use "transaction" to indicate that if any of the tasks within it fail,
# all should be rolled back (for each task that specifies an on_rollback
# handler).

# desc "A task demonstrating the use of transactions."
# task :long_deploy do
#   transaction do
#     update_code
#     disable_web
#     symlink
#     migrate
#   end
#
#   restart
#   enable_web
# end
#
# task :after_update_code, :roles => :app do
#   db_config = "#{shared_path}/config/database.yml.production"
#   run "cp #{db_config} #{release_path}/config/database.yml"
# end

desc "Symlink the database config file from shared directory to current release directory."
task :symlink_database_yml do
  run "ln -nsf #{shared_path}/config/database.yml #{release_path}/config/database.yml"
end
after 'deploy:update_code' , 'symlink_database_yml'
