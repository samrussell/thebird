def up_to_point(array, &block)
  last_index = array.index &block
  return array unless last_index

  array[0..last_index]
end

def from_point(array, &block)
  first_index = array.index &block
  return [] unless first_index
  
  array[first_index..-1]
end

def after_point(array, &block)
  first_index = array.index &block
  return [] unless first_index
  
  array[first_index+1..-1]
end
