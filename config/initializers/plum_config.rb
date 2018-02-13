module Plum
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  def messaging_client
    MessagingClient.new(Plum.config['events']['server'])
  end

  private

    def config_yaml
      YAML.safe_load(ERB.new(File.read("#{Rails.root}/config/config.yml")) \
                       .result, [Symbol], [], true)[Rails.env]
    end

    module_function :config, :config_yaml, :messaging_client
end

Hydra::Derivatives.kdu_compress_recipes = Plum.config['jp2_recipes']
