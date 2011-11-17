
class CollectingAuditor
  
  attr_reader :events
  
  def initialize
    @events = []
  end
  
  def audit type, message
    @events << CheekyDreams::AuditEvent.new(type, message)
  end
  
  def has_received? type, message
    @events.include? CheekyDreams::AuditEvent.new(type, message)
  end
end