#
# Description: <Method description here>
#

ems_id = $evm.root['dialog_ems_id']

values = {}

projects = $evm.vmdb('container_project').where(:ems_id => ems_id)
# projects = $evm.vmdb('container_project').where("deleted_on is null")
raise "VMDB lookup failed" if projects.nil?

projects.each do |project|
  next unless project.deleted_on.nil?
  $evm.log(:info, "#{project.name}: #{project.id}")
  values[project.name] = project.name
end

if values.empty?
  values['!'] = 'None available'
else
  # values['!'] = '< Choose >'
  values['< Create new project >'] = '< Create new project >'
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
