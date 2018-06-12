require "./lib/utils"

class Preflop
  attr_reader :plays, :hole_cards

  def initialize(plays, hole_cards)
    @plays = plays
    @hole_cards = hole_cards

    categorise_plays
  end

  def could_open?(seat_num)
    @possible_opens.any?{ |play| play.player.seat_num == seat_num }
  end

  def open_raised?(seat_num)
    first_raise && @possible_opens.include?(first_raise) && first_raise.player.seat_num == seat_num
  end

  def won_with_open_raise?(seat_num)
    open_raised?(seat_num) && @possible_threebets.all?{|play| play.type == :fold || play.type == :extra_returned}
  end

  def open_called?(seat_num)
    could_open?(seat_num) && plays_for_seat_num(seat_num).first.type == :call
  end

  def vpip?(seat_num)
    @plays.select{ |play| play.player.seat_num == seat_num }.first.type != :fold
  end

  def could_threebet?(seat_num)
    @possible_threebets.any?{ |play| play.player.seat_num == seat_num }
  end

  def threebet?(seat_num)
    threebet && threebet.player.seat_num == seat_num
  end

  def could_fourbet?(seat_num)
    @possible_fourbets.any?{ |play| play.player.seat_num == seat_num }
  end

  def fold_to_threebet?(seat_num)
    could_fourbet?(seat_num) && @possible_fourbets.select{ |play| play.player.seat_num == seat_num }.first.type == :fold
  end

  def fourbet?(seat_num)
    fourbet && fourbet.player.seat_num == seat_num
  end

  def first_raise
    possible_first_raise = @possible_first_raises.last
    
    possible_first_raise if possible_first_raise && possible_first_raise.type == :raise
  end

  def threebet
    possible_threebet = @possible_threebets.last
    
    possible_threebet if possible_threebet && possible_threebet.type == :raise
  end

  def fourbet
    possible_fourbet = @possible_fourbets.last
    
    possible_fourbet if possible_fourbet && possible_fourbet.type == :raise
  end

  private

  def categorise_plays
    @possible_opens = up_to_point(@plays) {|play| play.type != :fold}
    @possible_first_raises = up_to_point(@plays) {|play| play.type == :raise}
    after_first_raise = after_point(@plays) {|play| play.type == :raise}
    @possible_threebets = up_to_point(after_first_raise) {|play| play.type == :raise}
    after_threebet = after_point(after_first_raise) {|play| play.type == :raise}
    @possible_fourbets = up_to_point(after_threebet) {|play| play.type == :raise}
  end
end
