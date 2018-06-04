require "byebug"
require "./lib/preflop"

zoom_filenames = Dir["hand_histories_2018_06_04/*McNaught*.txt"]

hand_texts = []

zoom_filenames.each do |filename|
  data = File.read(filename, mode: "r:bom|utf-8").force_encoding("ASCII-8BIT")

  hand_texts += data.split("\n\n\n\n")
end

class Hand
  attr_reader :players, :preflop

  def initialize(players, preflop)
    @players = players
    @preflop = preflop
  end
end

class Player
  attr_reader :username, :seat_num, :stack_size

  def initialize(username, seat_num, stack_size)
    @username = username
    @seat_num = seat_num
    @stack_size = stack_size
  end
end

# only does 9-seat
def parse_players(player_lines)
  players = player_lines.map do |player_line|
    seat_num, username, stack_size = /\ASeat ([0-9]): (.+) \(\$([0-9.]+) in chips\)/.match(player_line).captures

    Player.new(username, seat_num, stack_size)
  end

  # button is now at the end
  players.rotate
end

def parse_preflop(preflop_lines)
  hole_card_line = preflop_lines.shift
  raise "Bad hole card line: #{hole_card_line}" unless /Dealt to .+ \[.. ..\]/.match(hole_card_line)

  if preflop_lines.any? { |line| /collected \$[0-9.]+ from pot/.match(line) }
    #won at flop
    winning_lines = preflop_lines.pop(2)
    raise "Preflop winning line fail: #{preflop_lines} #{winning_lines}" unless /collected \$[0-9.]+ from pot/.match(winning_lines[0])
  end

  plays = preflop_lines.flat_map do |preflop_line|
    if /: raises/.match(preflop_line)
      :raise
    elsif /: calls/.match(preflop_line)
      :call
    elsif /: folds/.match(preflop_line)
      :fold
    elsif /: checks/.match(preflop_line)
      :check
    elsif /\AUncalled bet/.match(preflop_line)
      nil
    elsif /has timed out/.match(preflop_line)
      nil
    elsif /is disconnected/.match(preflop_line)
      nil
    elsif /is connected/.match(preflop_line)
      nil
    elsif /said, ".+"/.match(preflop_line)
      nil
    else
      raise "Unrecognised preflop play: #{preflop_line}"
    end
  end

  Preflop.new(plays)
end

def parse_hand(hand_text)
  lines = hand_text.split("\n")
  description = lines.shift
  raise "Not a valid Zoom hand: #{description}" unless /\APokerStars Zoom Hand/.match(description)
  raise "Not NL2: #{description}" unless /Hold'em No Limit \(\$0\.01\/\$0\.02\)/.match(description)

  table_notes = lines.shift
  raise "Not 9-max or seat 1 is not the button #{table_notes}" unless /9-max Seat #1 is the button/.match(table_notes)

  players = parse_players(lines.shift(9))

  small_blind_text, big_blind_text = lines.shift(2)

  raise "Table order wrong: #{small_blind_text}" unless small_blind_text != "${players[0].username]: posts small blind $0.01"
  raise "Table order wrong: #{big_blind_text}" unless big_blind_text != "${players[0].username]: posts small blind $0.02"

  hole_cards_text = lines.shift

  raise "Hand import error: #{hole_cards_text}" unless hole_cards_text == "*** HOLE CARDS ***"

  preflop_lines = [].tap do |preflop_lines|
    until /\A\*\*\*/.match(lines[0])
      preflop_lines.push(lines.shift)
    end
  end

  preflop = parse_preflop(preflop_lines)

  Hand.new(players, preflop)
end

hands = hand_texts.map{|x| parse_hand(x)}

#puts hands
puts "Parsed #{hands.size} hands"

byebug

puts "yay"
