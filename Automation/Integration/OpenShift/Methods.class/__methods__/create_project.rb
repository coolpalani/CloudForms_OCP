#
# Description: <Method description here>
#

def log(level, msg)
  $evm.log(level, msg)
  # p msg
end

$evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}

require 'rest-client'

ems_id        = $evm.root['dialog_ems_id']
project       = $evm.root['dialog_project']
image         = $evm.root['dialog_image']
new_project   = $evm.root['dialog_new_project']
container     = $evm.root['dialog_container']
cpu           = $evm.root['dialog_cpu']
ram           = $evm.root['dialog_ram']
port          = $evm.root['dialog_port']
autoscale     = $evm.root['dialog_autoscale']

create = false

if project == '< Create new project >' || project.nil?
  raise 'New project name required' if new_project.length == 0
  project = new_project
  create = true
end
project = project.downcase

if create

  ems = $evm.vmdb('ManageIQ_Providers_ContainerManager').where(:id => ems_id)
  raise "EMS lookup failed" if ems.nil?
  log(:info, ems.inspect)
  ems = ems.first

  OSE_HOST  = ems.hostname
  OSE_PORT  = ems.port
  OSE_TOKEN = ems.authentication_key

  HEADERS = {
    :accept        => 'application/json',
    :content_type  => 'application/json',
    :authorization => "Bearer #{OSE_TOKEN}"
  }
  URL   = "https://#{OSE_HOST}:#{OSE_PORT}"

  ###########################
  # Do stuff...
  ###########################

  # oc new-project project1 --loglevel=8
  # POST https://master1.example.com:8443/oapi/v1/projectrequests

  query = "/oapi/v1/projectrequests"
  log(:info, "#{URL}#{query}")

  payload = {:kind=>"ProjectRequest",
   :apiVersion=>"v1",
   :metadata=>{:name=>project, :creationTimestamp=>nil}}.to_json
  log(:info, payload)

  rest_return = RestClient::Request.execute(
    :method     => :post,
    :url        => URL + query,
    :headers    => HEADERS,
    :payload    => payload,
    :verify_ssl => false
  )

  result = JSON.parse(rest_return)
  log(:info, result)

end
