class Indocker::Launchers::DTO::RemoteOperationDTO
  attr_reader :thread, :server, :operation, :message

  def initialize(thread, server, operation, message = nil)
    @thread = thread
    @server = server
    @operation = operation
    @message = message
  end
end