# allow logging of terminal commands

def command command_to_run
  puts " " + command_to_run.yellow if $verbose
  success = system command_to_run

  # appledoc always fails for me ... ?
  unless success && !command_to_run.start_with?("appledoc")
    puts (command_to_run + " failed!").red
  end
end

# a nice puts

def vputs text
  puts text.green if $verbose
end

class Array
  def listify
    length < 2 ? first.to_s : "#{self[0..-2] * ', '} and #{last}"
  end
end

module HashInit
  def initialize(*h)
    if h.length == 1 && h.first.kind_of?(Hash)
      h.first.each { |k,v| send("#{k}=",v) }
    end
  end
end
