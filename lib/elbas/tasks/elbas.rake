require 'elbas'

include Elbas::Logger

namespace :elbas do
  task :ssh do
    include Capistrano::DSL

    info "SSH commands:"
    env.servers.to_a.each.with_index do |server, i|
      info "    #{i + 1}) ssh #{fetch(:user)}@#{server.hostname}"
    end
  end

  task :deploy do
    fetch(:aws_autoscale_group).each do |autoscale_group|
      autoscale_group_name = autoscale_group[:name]
      keep_previous = autoscale_group[:keep_previous]

      asg = Elbas::AWS::AutoscaleGroup.new autoscale_group_name

      info "[#{autoscale_group_name}] Creating AMI from a running instance..."
      ami = Elbas::AWS::AMI.create asg.instances.running.sample
      ami.tag 'ELBAS-Deploy-group', asg.name
      ami.tag 'ELBAS-Deploy-id', env.timestamp.to_i.to_s
      info  "Created AMI: #{ami.id}"

      info "[#{autoscale_group_name}] Updating launch template with the new AMI..."
      launch_template = asg.launch_template.update ami
      info "[#{autoscale_group_name}] Updated launch template, new default version = #{launch_template.version}"

      info "[#{autoscale_group_name}] Cleaning up old AMIs..."

      ancestor_count = ami.ancestors.size

      ami.ancestors.slice(keep_previous,ancestor_count).each do |ancestor|
        info "[#{autoscale_group_name}] Deleting old AMI: #{ancestor.id}"
        ancestor.delete
      end
    end

    info "Deployment complete!"
  end
end
