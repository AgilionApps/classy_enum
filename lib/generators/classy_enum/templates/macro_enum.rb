require 'classy_enum/macros'

enum :<%= class_name.underscore %>
<% values.each do |arg| %>
  enum :<%= arg.underscore %>
<%- end -%>
end
