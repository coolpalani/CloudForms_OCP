#
# Description: <Method description here>
#

def log(level, msg)
  $evm.log(level, msg)
  # p msg
end

$evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}

template      = $evm.root['dialog_template']

###########################
# Do stuff...
###########################

container_template = $evm.vmdb('container_template').find_by(:name => template)

if container_template.nil?
  display_string = "Select template above...\n"
else
  display_string = ""
  container_template.container_template_parameters.each do |param|
    $evm.log(:info, param.name)
    display_string += "#{param.name}=#{param.value}\n"
  end
  display_string = "Template has no parameters\n" if display_string.length == 0
end

## To do - Sort parameter list

list_values = {
  'sort_by'    => :value,
  'data_type'  => :string,
  'required'   => true,
  'value'      => display_string
}
list_values.each { |key, value| $evm.object[key] = value }
