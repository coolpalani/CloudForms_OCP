#
# Description: <Method description here>
#
  
values = {}

templates = $evm.vmdb('container_template')
raise "VMDB lookup failed" if templates.nil?

templates.all.each do |template|
  if template.respond_to?(:deleted_on)
    next unless template.deleted_on.nil?
  end
  $evm.log(:info, template.name)
  values[template.name] = template.name
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
