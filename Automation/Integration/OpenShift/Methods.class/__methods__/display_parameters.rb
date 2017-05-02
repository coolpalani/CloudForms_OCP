#
# Description: <Method description here>
#

template = $evm.root['dialog_template']
# ems_id   = $evm.root['dialog_ems_id']

# Must us 'find_by' otherwise 'container_template_parameters' method isn't present
# container_template = $evm.vmdb('container_template').find_by(:name => template)
# container_template = $evm.vmdb('container_template').where(:name => template, :ems_id => ems_id)
# container_template = $evm.vmdb('container_template').where(:id => template)
container_template = $evm.vmdb('container_template').find_by(:id => template)

if container_template.nil?
  display_string = "Select template above...\n"
else
  display_string = ""
  container_template.container_template_parameters.each do |param|
    # $evm.log(:info, param.name)
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
