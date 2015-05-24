desc 'Bootstraps the app'
task :bootstrap do
  sh "bundle install"
end

begin
  require 'bundler'
  Bundler.require

  require 'rubocop/rake_task'

  desc 'Sets up installation of apps for cocoadocs'
  task :install_tools do
    if `which brew`.length == 0
      puts "Homebrew was not found, would you like us to install it for you? yes/no"
      exit unless STDIN.gets.strip == 'yes'

      `ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
    end

    check_and_install "cloc"
    check_and_install "s3cmd"
    check_and_install "appledoc"
    check_and_install "carthage"
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
