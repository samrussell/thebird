class Preflop
  attr_reader :plays

  def initialize(plays)
    @plays = plays
  end

  def could_open?(position)
    return true if position == 0

    @plays[0...position].all?{|play| play.type == :fold}
  end

  def open_raised?(position)
    could_open?(position) && @plays[position].type == :raise
  end

  def open_called?(position)
    could_open?(position) && @plays[position].type == :call
  end

  def vpip?(position)
    (@plays[position].type == :call || @plays[position].type == :raise)
  end
end
