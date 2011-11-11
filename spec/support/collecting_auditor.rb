AuditEvent = Struct.new(:type, :message)

class CollectingAuditor
  
  attr_reader :events
  
  def initialize
    @events = []
  end
  
  def audit type, message
    @events << AuditEvent.new(type, message)
  end
  
  def has_received? type, message
    @events.include? AuditEvent.new(type, message)
  end
end