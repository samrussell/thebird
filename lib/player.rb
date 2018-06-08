class Player
  attr_reader :username, :seat_num, :stack_size
  attr_accessor :winnings

  def initialize(username, seat_num, stack_size)
    @username = username
    @seat_num = seat_num
    @stack_size = stack_size
    @winnings = 0.0
  end
end
