def reset_class_variables(klass)
  klass.instance_variables.each do |var|
    klass.instance_variable_set var, nil
  end
end
