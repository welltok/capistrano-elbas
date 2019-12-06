require 'capistrano/dsl'

load File.expand_path("../tasks/elbas.rake", __FILE__)

def autoscale(groupname, properties = {})
  include Capistrano::DSL
  include Elbas::Logger

  if fetch(:aws_autoscale_group).nil?
    set :aws_autoscale_group, [{name: groupname, keep_previous: properties.fetch(:keep_previous_amis, 0)}]
  else
    set :aws_autoscale_group, fetch(:aws_autoscale_group).push({name: groupname, keep_previous: properties.fetch(:keep_previous_amis, 0)})
  end

  asg = Elbas::AWS::AutoscaleGroup.new groupname
  instances = asg.instances.running

  instances.each.with_index do |instance, i|
    info "Adding server: #{instance.hostname}"

    props = nil
    props = yield(instance, i) if block_given?
    props ||= properties

    server instance.hostname, props
  end

  if instances.any?
    after 'deploy', 'elbas:deploy'
  else
    error <<~MESSAGE
      Could not create AMI because no running instances were found in the specified
      AutoScale group. Ensure that the AutoScale group name is correct and that
      there is at least one running instance attached to it.
    MESSAGE
  end
end
