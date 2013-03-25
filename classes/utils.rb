def vputs text
  puts text.green if @verbose 
end

class Array
  def listify
    length < 2 ? first.to_s : "#{self[0..-2] * ', '} and #{last}"
  end
end
