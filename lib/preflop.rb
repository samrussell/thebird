class Preflop
  def initialize(plays)
    @plays = plays
  end

  def could_open?(position)
    return true if position == 0

    @plays[0...position].all?{|play| play == :fold}
  end

  def open_raised?(position)
    could_open?(position) && @plays[position] == :raise
  end

  def open_called?(position)
    could_open?(position) && @plays[position] == :call
  end

  def vpip?(position)
    (@plays[position] == :call || @plays[position] == :raise)
  end
end
