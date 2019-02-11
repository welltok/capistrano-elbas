module Elbas
  module AWS
    class LaunchTemplate < Base
      attr_reader :id, :name, :version

      def initialize(id, name, version)
        @id = id
        @name = name
        @version = version
      end

      def update(ami)
        latest = aws_client.create_launch_template_version({
          launch_template_data: { image_id: ami.id },
          launch_template_id: self.id,
          source_version: self.version
        })

        self.class.new id, name, latest.launch_template_version
      end

      private
        def aws_namespace
          ::Aws::EC2
        end
    end
  end
end