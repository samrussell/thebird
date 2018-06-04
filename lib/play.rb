class Play
  attr_reader :type, :player, :bet_change, :total

  def initialize(type, player, bet_change, total)
    @type = type
    @player = player
    @bet_change = bet_change
    @total = total
  end
end
