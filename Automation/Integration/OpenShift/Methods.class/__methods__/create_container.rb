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

project = new_project if project == '< Create new project >'

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

# oc run busybox1 --image=busybox --limits=cpu=600m,memory=1000Mi --requests=cpu=300m,memory=600Mi --loglevel=8
# POST https://ocpmaster.winexample.local:8443/oapi/v1/namespaces/nick001/deploymentconfigs

query = "/oapi/v1/namespaces/#{project}/deploymentconfigs"
log(:info, "#{URL}#{query}")

payload = {:kind=>"DeploymentConfig",
 :apiVersion=>"v1",
 :metadata=>
  {:name=>container, :creationTimestamp=>nil, :labels=>{:run=>container}},
 :spec=>
  {:strategy=>{:resources=>{}},
   :triggers=>nil,
   :replicas=>1,
   :test=>false,
   :selector=>{:run=>container},
   :template=>
    {:metadata=>{:creationTimestamp=>nil, :labels=>{:run=>container}},
     :spec=>
      {:containers=>
        [{:name=>container,
          :image=>image,
          :resources=>
           {:limits=>{:cpu=>"#{cpu}m", :memory=>"#{ram}Mi"},
            :requests=>{:cpu=>"300m", :memory=>"600Mi"}}}]}}},
 :status=>{}}.to_json
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
