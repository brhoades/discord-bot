class VoiceMessage
  attr_accessor :owner, :channel, :extra, :file

  def initialize(owner, channel, file, extra={})
    @owner = owner
    @channel = channel
    @file = file

    @extra = extra
  end

  def delete=(rhs)
    @extra[:delete] = rhs
  end

  def delete?
    @extra.has_key? :delete and @extra[:delete]
  end

  def volume=(rhs)
    @extra[:volume] = rhs
  end

  def volume
    @extra[:volume] || "0.1"
  end
end
