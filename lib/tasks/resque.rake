require "rake"
require "resque"
require "resque/tasks"

task "resque:setup" => :environment