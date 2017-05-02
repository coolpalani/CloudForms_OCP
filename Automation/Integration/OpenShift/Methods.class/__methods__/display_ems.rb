#
# Description: <Method description here>
#

values = {}

ems = $evm.vmdb('ManageIQ_Providers_ContainerManager')
raise "VMDB lookup failed" if ems.nil?

ems.all.each do |e|
  $evm.log(:info, "#{e.name}: #{e.id}")
  values[e.id] = e.name
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
