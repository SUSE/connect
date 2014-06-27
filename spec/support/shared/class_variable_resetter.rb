def reset_class_variables(klass)
  klass.class_variables.each do |var|
    klass.class_variable_set var, nil
  end
end
