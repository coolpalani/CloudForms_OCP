#
# Description: <Method description here>
#

def log(level, msg)
  $evm.log(level, msg)
  # p msg
end

$evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}

require 'rest-client'

project       = $evm.root['dialog_project']
image         = $evm.root['dialog_image']
new_project   = $evm.root['dialog_new_project']
container     = $evm.root['dialog_container']
cpu           = $evm.root['dialog_cpu']
ram           = $evm.root['dialog_ram']
port          = $evm.root['dialog_port']
autoscale     = $evm.root['dialog_autoscale']

project = new_project if project == '< Create new project >'

ems = $evm.vmdb('ManageIQ_Providers_ContainerManager').first
# # ems = $evm.vmdb('ext_management_system').where("type = 'ManageIQ::Providers::OpenshiftEnterprise::ContainerManager'").first
log(:info, ems.inspect)

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

# oc expose dc/busybox1 --port=4000 --name=busyboxonport4000 --loglevel=8
# POST https://master1.example.com:8443/api/v1/namespaces/project1/services

query = "/api/v1/namespaces/#{project}/services"
log(:info, "#{URL}#{query}")

payload = {:kind=>"Service",
 :apiVersion=>"v1",
 :metadata=>
  {:name=>"#{container}port#{port}",
   :creationTimestamp=>nil,
   :labels=>{:run=>container}},
 :spec=>
  {:ports=>[{:protocol=>"TCP", :port=>port.to_i, :targetPort=>port.to_i}],
   :selector=>{:run=>container}},
 :status=>{:loadBalancer=>{}}}.to_json
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
