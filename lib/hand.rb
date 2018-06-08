class Hand
  attr_reader :players, :preflop

  def initialize(players, preflop)
    @players = players
    @preflop = preflop
  end
end
