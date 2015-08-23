require 'mina/bundler'
require 'mina/git'
require 'mina/rvm'

set :domain, 'api.cocoadocs.org'
set :user, 'maddern'

set :deploy_to, '/Users/maddern/dev/deploys/'
set :repository, 'https://github.com/CocoaPods/cocoadocs.org.git'
set :branch, 'master'

desc "Deploys the current version to the server."
task :deploy do
  deploy do
    queue 'pwd'
    queue 'rvm use 2.1.3'
    queue 'bundle install'

    to :launch do
      queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
      queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
    end
  end
end