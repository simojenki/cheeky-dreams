

class CollectingAuditor
  
  attr_reader :errors
  
  def initialize
    @errors = []
  end
  
  def unhandled_error e
    @errors << e
  end
  
  def has_received? e
    @errors.include? e
  end
end