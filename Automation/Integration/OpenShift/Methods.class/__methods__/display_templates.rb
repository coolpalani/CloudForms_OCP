#
# Description: <Method description here>
#

ems_id = $evm.root['dialog_ems_id']

values = {}

templates = $evm.vmdb('container_template').where(:ems_id => ems_id)
raise "VMDB lookup failed" if templates.nil?

templates.each do |template|
  if template.respond_to?(:deleted_on)
    next unless template.deleted_on.nil?
  end
  $evm.log(:info, "#{template.name}: #{template.id}")
  values[template.id] = template.name
end

if values.empty?
  values['!'] = 'None available'
else
  values['!'] = '< Choose >'
end

list_values = {
  'sort_by'    => :value,
  'data_type'  => :string,
  'required'   => true,
  'values'     => values,
}
list_values.each do |key, value| 
  $evm.object[key] = value
end
