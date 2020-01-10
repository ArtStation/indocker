class Indocker::Server
  include Indocker::Concerns::Inspectable

  attr_reader :name, :host, :user, :port

  def initialize(name:, host:, user:, port:)
    @name = name
    @host = host
    @user = user
    @port = port
  end

  def ==(value)
    if value.is_a?(Indocker::Server)
      @name == value.name
    else
      super
    end
  end
end