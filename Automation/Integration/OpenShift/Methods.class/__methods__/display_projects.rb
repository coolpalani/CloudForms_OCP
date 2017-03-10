#
# Description: <Method description here>
#
  
values = {}

projects = $evm.vmdb('container_project')
# projects = $evm.vmdb('container_project').where("deleted_on is null")
raise "VMDB lookup failed" if projects.nil?

projects.all.each do |project|
  next unless project.deleted_on.nil?
  $evm.log(:info, project.name)
  values[project.name] = project.name
end

if values.empty?
  values['!'] = 'None available'
else
  values['!'] = '< Choose >'
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
