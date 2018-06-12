class Hand
  attr_reader :players, :preflop, :streets

  def initialize(players, preflop, streets)
    @players = players
    @preflop = preflop
    @streets = streets
  end
end
