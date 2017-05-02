#
# Description: <Method description here>
#

def log(level, msg)
  $evm.log(level, msg)
end

def replace_parameters(hash, old_v, new_v)
  hash.each do |k, v|
    if v.is_a?(String)
      if v == "\$\{#{old_v}\}"
        v.replace new_v
      elsif v.match(/\$\{#{old_v}\}/)
        v.replace v.gsub(/\$\{#{old_v}\}/, new_v)
      end
    elsif v.is_a?(Hash)
      replace_parameters(v, old_v, new_v)
    elsif v.is_a?(Array)
      v.flatten.each { |x| replace_parameters(x, old_v, new_v) if x.is_a?(Hash) }
    end
  end
  hash
end

def call_rest(api_url, payload)
  log(:info, "URL: #{api_url}")
  # log(:info, payload.to_json)

  rest_return = RestClient::Request.execute(
    :method     => :post,
    :url        => api_url,
    :headers    => HEADERS,
    :payload    => payload.to_json,
    :verify_ssl => false
  )
  log(:info, "Return code: #{rest_return.code}")

  result = JSON.parse(rest_return)
  log(:info, result)
end

$evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}

require 'rest-client'

ems_id        = $evm.root['dialog_ems_id']
project       = $evm.root['dialog_project']
template      = $evm.root['dialog_template']
template_parameters      = $evm.root['dialog_template_parameters']
new_project   = $evm.root['dialog_new_project']
# container     = $evm.root['dialog_container']
cpu           = $evm.root['dialog_cpu']
ram           = $evm.root['dialog_ram']
port          = $evm.root['dialog_port']
autoscale     = $evm.root['dialog_autoscale']

log(:info, "template_parameters: #{template_parameters}")

parameters_array = []

empty_values = false
unless template_parameters.match(/(Template has no parameters|Select template above)/) || template_parameters.nil?
  template_parameters.split("\n").each do | parameter |
    parameter_split = parameter.match(/(.*)=(.*)/)
    key = parameter_split[1]
    value = parameter_split[2]
    empty_values = true if value.empty?
    parameters_array << {:name=>key, :value=>value}
  end
  raise "Empty parameter values detected" if empty_values
end

log(:info, "parameters_array: #{parameters_array}")

project = new_project if project == '< Create new project >' || project.nil?

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

# Must us 'find_by' otherwise 'objects' method isn't present
# container_template = $evm.vmdb('container_template').find_by(:name => template)
# container_template = $evm.vmdb('container_template').where(:name => template, :ems_id => ems_id)
container_template = $evm.vmdb('container_template').find_by(:id => template)
raise 'Container template not found' if container_template.nil?

container_template.objects.each do |resource|

  log(:info, "resource[:kind]: #{resource[:kind]}")
  log(:info, resource)
  payload = resource

  case resource[:kind]
  when "Secret"
    log(:info, "Dropping #{resource[:kind]}")
    next
  when "Service"
    query = "/api/v1/namespaces/#{project}/services"

    # Set requested port
    unless port.nil?
      begin
        payload[:spec][:ports].first[:port] = port.to_i
      rescue => err
        log(:warn, "There was a problem setting the requested port")
        log(:warn, err)
      end
    end

  when "DeploymentConfig"
    query = "/oapi/v1/namespaces/#{project}/deploymentconfigs"

    # Name required for subsequent actions like scaling
    begin
      $evm.set_state_var("container", payload[:spec][:template][:spec][:containers].first[:name])
    rescue => err
      log(:warn, "Container name not found in template spec")
    end

    # Override the parameters with those from the dialogue unless template has no parameters
    payload[:spec][:template][:spec][:containers].first[:env] = parameters_array unless parameters_array.empty?

    # Set container resources
    unless cpu.nil? || ram.nil?
      begin
        container_resources = {
          :limits=>{:cpu=>"#{cpu}m", :memory=>"#{ram}Mi"},
          :requests=>{:cpu=>"#{cpu.to_i/2}m", :memory=>"#{ram.to_i/2}Mi"}
        }
        payload[:spec][:template][:spec][:containers].first[:resources] = container_resources
      rescue => err
        log(:warn, "There was a problem setting the requested limits")
        log(:warn, err)
      end
    end

    # Set requested port
    unless port.nil?
      begin
        payload[:spec][:template][:spec][:containers].first[:livenessProbe][:tcpSocket][:port] = port.to_i
        payload[:spec][:template][:spec][:containers].first[:ports].first[:containerPort] = port.to_i
      rescue => err
        log(:warn, "There was a problem setting the requested port")
        log(:warn, err)
      end
    end

  when "ReplicationController"
    query = "/api/v1/namespaces/#{project}/replicationcontrollers"

  when "ConfigMap"
    query = "/api/v1/namespaces/#{project}/configmaps"
    
  else
    # Testing...
    log(:warn, "Testing #{resource[:kind]}")
    query = "/api/v1/namespaces/#{project}/#{resource[:kind].downcase}s"
    # log(:warn, "Dropping #{resource[:kind]}")
    # next
  end

  # Replace variablised parameters
  parameters_array.each do |parm| payload = replace_parameters(payload, parm[:name], parm[:value]) end

  log(:info, payload)
  call_rest("#{URL}#{query}", payload)
end
