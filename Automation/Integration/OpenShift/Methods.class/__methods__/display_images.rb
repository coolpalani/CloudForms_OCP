#
# Description: <Method description here>
#
  
values = {}

images = $evm.vmdb('container_image')
raise "VMDB lookup failed" if images.nil?

images.all.each do |image|
  $evm.log(:info, image.name)
  values[image.name] = image.name
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
