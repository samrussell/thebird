require "byebug"
require "./lib/preflop"
require "./lib/play"

zoom_filenames = Dir["hand_histories_2018_06_04/*McNaught*.txt"] #[0...10]

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
  attr_accessor :winnings

  def initialize(username, seat_num, stack_size)
    @username = username
    @seat_num = seat_num
    @stack_size = stack_size
    @winnings = 0.0
  end
end

# only does 9-seat
def parse_players(player_lines)
  players = player_lines.map do |player_line|
    seat_num, username, stack_size = /\ASeat ([0-9]): (.+) \(\$([0-9.]+) in chips\)/.match(player_line).captures

    Player.new(username, seat_num, stack_size)
  end

  # button is now at the end - this needs to change if we ever do non-zoom hands
  players.rotate
end

def parse_preflop(preflop_lines, players_by_username)
  hole_card_line = preflop_lines.shift
  raise "Bad hole card line: #{hole_card_line}" unless /Dealt to .+ \[.. ..\]/.match(hole_card_line)

  # filter junk lines

  preflop_lines = preflop_lines.reject do |preflop_line|
    /has timed out/.match(preflop_line) ||
      /is disconnected/.match(preflop_line) ||
      /is connected/.match(preflop_line) ||
      /said, ".+"/.match(preflop_line)
  end

  if preflop_lines.any? { |line| /collected \$[0-9.]+ from pot/.match(line) }
    #won at flop
    winning_lines = preflop_lines.pop(2)
    raise "Preflop winning line fail: #{preflop_lines} #{winning_lines}" unless /collected \$[0-9.]+ from pot/.match(winning_lines[0])
  end

  plays = preflop_lines.flat_map do |preflop_line|
    if /(.+): raises \$([0-9.]+) to \$([0-9.]+)/.match(preflop_line)
      Play.new(:raise, players_by_username[$1], $2.to_f, $3.to_f)
    elsif /(.+): calls \$([0-9.]+)/.match(preflop_line)
      Play.new(:call, players_by_username[$1], 0.0, $2.to_f)
    elsif /(.+): folds/.match(preflop_line)
      Play.new(:fold, players_by_username[$1], 0.0, nil)
    elsif /(.+): checks/.match(preflop_line)
      Play.new(:check, players_by_username[$1], 0.0, nil)
    elsif /\AUncalled bet \(\$([0-9.]+)\) returned to (.+)/.match(preflop_line)
      Play.new(:extra_returned, players_by_username[$2], -$1.to_f, nil)
    else
      raise "Unrecognised preflop play: #{preflop_line}"
    end
  end

  Preflop.new(plays)
end

def parse_street(street_name, street_lines, players_by_username)
  # filter junk lines

  street_lines = street_lines.reject do |street_line|
    /has timed out/.match(street_line) ||
      /is disconnected/.match(street_line) ||
      /is connected/.match(street_line) ||
      /said, ".*"/.match(street_line)
  end

  if street_lines.any? { |line| /collected \$[0-9.]+ from pot/.match(line) }
    #won at flop
    winning_lines = street_lines.pop(2)
    raise "#{street_name} winning line fail: #{street_lines} #{winning_lines}" unless /collected \$[0-9.]+ from pot/.match(winning_lines[0])
  end

  plays = street_lines.flat_map do |street_line|
    if /(.+): raises \$([0-9.]+) to \$([0-9.]+)/.match(street_line)
      Play.new(:raise, players_by_username[$1], $2.to_f, $3.to_f)
    elsif /(.+): bets \$([0-9.]+)/.match(street_line)
      Play.new(:bet, players_by_username[$1], $2.to_f, $2.to_f)
    elsif /(.+): calls \$([0-9.]+)/.match(street_line)
      Play.new(:call, players_by_username[$1], 0.0, $2.to_f)
    elsif /(.+): folds/.match(street_line)
      Play.new(:fold, players_by_username[$1], 0.0, nil)
    elsif /(.+): checks/.match(street_line)
      Play.new(:check, players_by_username[$1], 0.0, nil)
    elsif /\AUncalled bet \(\$([0-9.]+)\) returned to (.+)/.match(street_line)
      Play.new(:extra_returned, players_by_username[$2], -$1.to_f, nil)
    else
      byebug
      raise "Unrecognised street play: #{street_line}"
    end
  end

  plays
end

def parse_summary(summary_lines, players_by_username)
  pot_line = summary_lines.shift

  # handles side pots but ignores the info
  pot, rake = /Total pot \$([0-9.]+).+Rake \$([0-9.]+)/.match(pot_line).captures

  players = players_by_username.values

  # sanity check
  total_gains = players.map(&:winnings).reduce(:+) * -1.0

  if total_gains.round(2) != pot.to_f.round(2)
    byebug
    raise "Calculated pot wrong: pot is #{pot} but we got #{total_gains}"
  end

  if /Hand was run/.match(summary_lines[0]) || /Board /.match(summary_lines[0])
    board_lines = [].tap do |board_lines|
      until /Seat [0-9]/.match(summary_lines[0])
        board_lines.push(summary_lines.shift)
      end
    end
  end

  raise "Bad summary: not enough lines #{summary_lines}" unless summary_lines.size == 9

  summary_lines.each do |summary_line|
    win_without_showdown_regex = /Seat [0-9]: (.+) collected \(\$([0-9.]+)\)/
    win_at_showdown_regex = /Seat [0-9]: (.+) showed/
    if win_without_showdown_regex.match(summary_line)
      username = $1
      winnings = $2.to_f
      unless players_by_username.include?(username)
        username = /(.+) \(.+\)/.match(username).captures[0]
      end
      players_by_username[username].winnings += winnings
    elsif win_at_showdown_regex.match(summary_line)
      username = $1
      unless players_by_username.include?(username)
        username = /(.+) \(.+\)/.match(username).captures[0]
      end
      winnings_array = summary_line.scan(/won \(\$([0-9.]+)\)/)
      winnings = winnings_array.reduce(0) {|sum, captures| captures[0].to_f + sum}
      players_by_username[username].winnings += winnings
    end
  end

  net_winnings = players.map(&:winnings).reduce(:+) * -1.0

  if net_winnings.round(2) != rake.to_f.round(2)
    byebug
    raise "Calculated rake wrong: rake is #{rake} but we got #{net_winnings}"
  end
end

def evaluate_plays(plays, starting_bet_amount)
  bet_size = -starting_bet_amount
  plays.each do |play|
    if play.type == :call
      # need to handle all-in calls
      play.player.winnings -= play.total
    elsif play.type == :extra_returned
      play.player.winnings -= play.bet_change
    elsif play.type == :bet
      bet_size = -starting_bet_amount - play.total
      play.player.winnings = bet_size
    elsif play.type == :raise
      bet_size = -starting_bet_amount - play.total
      play.player.winnings = bet_size
    end
  end
end

def parse_hand(hand_text)
  lines = hand_text.split("\n")
  description = lines.shift
  raise "Not a valid Zoom hand: #{description}" unless /\APokerStars Zoom Hand/.match(description)
  raise "Not NL2: #{description}" unless /Hold'em No Limit \(\$0\.01\/\$0\.02\)/.match(description)

  table_notes = lines.shift
  raise "Not 9-max or seat 1 is not the button #{table_notes}" unless /9-max Seat #1 is the button/.match(table_notes)

  players = parse_players(lines.shift(9))
  players_by_username = players.each.with_object({}) do |player, hash|
    hash[player.username] = player
  end

  small_blind_text, big_blind_text = lines.shift(2)
  small_blind_username, small_blind_amount = /(.+): posts small blind \$([0-9.]+)/.match(small_blind_text).captures
  big_blind_username, big_blind_amount = /(.+): posts big blind \$([0-9.]+)/.match(big_blind_text).captures
  players_by_username[small_blind_username].winnings -= small_blind_amount.to_f
  players_by_username[big_blind_username].winnings -= big_blind_amount.to_f

  raise "Table order wrong: #{small_blind_text}" unless small_blind_text != "${players[0].username]: posts small blind $0.01"
  raise "Table order wrong: #{big_blind_text}" unless big_blind_text != "${players[0].username]: posts small blind $0.02"

  hole_cards_text = lines.shift

  raise "Hand import error: #{hole_cards_text}" unless hole_cards_text == "*** HOLE CARDS ***"

  preflop_lines = [].tap do |preflop_lines|
    until /\A\*\*\*/.match(lines[0])
      preflop_lines.push(lines.shift)
    end
  end

  preflop = parse_preflop(preflop_lines, players_by_username)
  bet_size = 

  streets = []

  until /\*\*\* SUMMARY \*\*\*/.match(lines[0]) || /\*\*\* .*SHOW DOWN \*\*\*/.match(lines[0])
    street_name = /\*\*\* (.+) \*\*\*/.match(lines.shift)
    street_lines = [].tap do |street_lines|
      until /\A\*\*\*/.match(lines[0])
        street_lines.push(lines.shift)
      end
    end

    streets.push(parse_street(street_name, street_lines, players_by_username))
  end

  evaluate_plays(preflop.plays, 0.0)

  streets.each do |street|
    previous_bet_size = players.map(&:winnings).min * -1.0
    evaluate_plays(street, previous_bet_size)
  end

  # skip show down
  until /\*\*\* SUMMARY \*\*\*/.match(lines[0])
    lines.shift
  end
  summary_headline = lines.shift

  summary = parse_summary(lines, players_by_username)

  Hand.new(players, preflop)
end

#hands = hand_texts[0..1000].map{|x| parse_hand(x)}
hands = hand_texts.map{|x| parse_hand(x)}

#puts hands
puts "Parsed #{hands.size} hands"

byebug

puts "yay"
