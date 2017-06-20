desc 'Bootstraps the app'
task :bootstrap do
  sh "bundle install"
end

begin
  require 'bundler'
  Bundler.require

  require 'rubocop/rake_task'
  require 'net/ssh'
  require 'net/ssh/shell'

  def run_ssh_commands commands
    puts "Connecting to api.cocoadocs.org:"
    Net::SSH.start('api.cocoadocs.org', 'cocoadocs') do |ssh|
      ssh.shell do |sh|
        sh.execute 'cd cocoadocs.org'
        commands.each do |command|
          puts command.yellow
          sh.execute command
        end
        sh.execute 'exit'
      end
    end

  end

  desc 'Starts the server via SSH'
  desc 'Updates the server via SSH'
  task :start do
    run_ssh_commands [
      'killall "foreman: master"',
      'screen -d -m -S "cocoadocs" bundle exec foreman start'
    ]
  end

  desc 'Updates the server via SSH'
  task :deploy do
    run_ssh_commands [
      'killall "foreman: master"',
      'git stash',
      'git pull',
      'bundle install',
      'screen -d -m -S "cocoadocs" bundle exec foreman start'
    ]
  end

  desc 'Check out the logs on the live server'
  task :logs do
    run_ssh_commands ["screen -r cocoadocs"]
  end

  desc 'Re-runs documentation for a CocoaPod via SSH'
  task :doc, :name do |t, args|
    run_ssh_commands ["bundle exec foreman run ruby cocoadocs.rb cocoadocs doc #{args.name} --verbose"]
  end

  desc 'Run a command on the server via SSH'
  task :exec, :command do |t, args|
    run_ssh_commands [args.command]
  end

  desc 'Re-runs x days worth of documentation for a CocoaPod via SSH'
  task :days, :number do |t, args|
    run_ssh_commands ["bundle exec foreman run ruby cocoadocs.rb cocoadocs days #{args.number} --verbose"]
  end

  desc 'Delete all docs for a pod'
  task :cocoadocs_rm_pod, :pod do |t, args|
    exit(1) if args.count != 1
    exit(1) if args.first == "."
    exit(1) if args.first == ".."
    system "aws s3 rm --recursive s3://buddybuild-cocoadocs/docsets/#{args.pod}"
  end

  desc 'Delete docs for a pod versions'
  task :cocoadocs_rm_pod_version, :pod, :version do |t, args|
    exit(1) if args.count != 2
    exit(1) if args.first == "."
    exit(1) if args.first == ".."
    system "aws s3 rm --recursive s3://buddybuild-cocoadocs/docsets/#{args.pod}/#{args.version}"
  end

  desc 'Sets up installation of apps for cocoadocs'
  task :install_tools do
    if `which brew`.length == 0
      puts "Homebrew was not found, would you like us to install it for you? yes/no"
      exit unless STDIN.gets.strip == 'yes'

      `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
    end

    check_and_install "cloc"
    check_and_install "appledoc"
    check_and_install "carthage"

    # Install pip and AWS
    `which pip || (curl https://bootstrap.pypa.io/get-pip.py | python)`
    `sudo pip install awscli`
  end

  def check_and_install app
    if `which #{app}`.length == 0
      Bundler.with_clean_env do
        `brew install #{app}`
      end
    end
  end

  def specs(dir)
    FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
  end

  desc 'Runs all the specs'
  task :specs do
    sh "bundle exec bacon #{specs('**')}"
  end

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.patterns = ['classes', 'spec']
  end

  # TODO: Put rubocop in by default
  task :default => :specs
rescue LoadError => e
  $stderr.puts "\033[0;31m" \
    '[!] Some Rake tasks haven been disabled because the environment' \
    ' couldn’t be loaded. Be sure to run `rake bootstrap` first or use the ' \
    "VERBOSE environment variable to see errors.\e[0m"
  if ENV['VERBOSE']
    $stderr.puts e.message
    $stderr.puts e.backtrace
    $stderr.puts
  end
end
