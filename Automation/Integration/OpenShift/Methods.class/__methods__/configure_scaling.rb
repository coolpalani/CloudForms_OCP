#
# Description: <Method description here>
#

def log(level, msg)
  $evm.log(level, msg)
end

$evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}

require 'rest-client'

project       = $evm.root['dialog_project']
new_project   = $evm.root['dialog_new_project']
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

container = $evm.get_state_var("container") if $evm.state_var_exist?("container")
raise "Container name not found" if container.nil?

###########################
# Do stuff...
###########################

# oc autoscale dc/busybox1 --min 1 --max 10 --cpu-percent=80 --loglevel=8
# POST https://master1.example.com:8443/apis/autoscaling/v1/namespaces/project1/horizontalpodautoscalers

query = "/apis/autoscaling/v1/namespaces/#{project}/horizontalpodautoscalers"
log(:info, "#{URL}#{query}")

payload = {:kind=>"HorizontalPodAutoscaler",
 :apiVersion=>"autoscaling/v1",
 :metadata=>{:name=>container, :creationTimestamp=>nil},
 :spec=>
  {:scaleTargetRef=>
    {:kind=>"DeploymentConfig", :name=>container, :apiVersion=>"v1"},
   :minReplicas=>1,
   :maxReplicas=>autoscale,
   :targetCPUUtilizationPercentage=>80},
 :status=>{:currentReplicas=>0, :desiredReplicas=>0}}.to_json
log(:info, payload)

rest_return = RestClient::Request.execute(
  :method     => :post,
  :url        => URL + query,
  :headers    => HEADERS,
  :payload    => payload,
  :verify_ssl => false
)

log(:info, "Return code: #{rest_return.code}")

result = JSON.parse(rest_return)
log(:info, result)
