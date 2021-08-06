module Counter::Configurable
  extend ActiveSupport::Concern

  def config=config
    @config = config
  end

  def config
    @config
  end
end
