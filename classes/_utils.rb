# allow logging of terminal commands

def command(command_to_run)
  puts " " + command_to_run.yellow if $verbose
  success = system(command_to_run)

  # appledoc always fails for me ... ?
  if !success && !command_to_run.strip.start_with?("vendor/appledoc")
    puts (command_to_run + " failed!").red
  end
  
  success
end

# a nice puts

def vputs(text)
  puts text.green if $verbose
end

class Array
  def listify
    length < 2 ? first.to_s : "#{self[0..-2] * ', '} and #{last}"
  end
end

module HashInit
  def initialize(*h)
    if h.length == 1 && h.first.is_a?(Hash)
      h.first.each { |k, v| send("#{k}=", v) }
    end
  end
end
