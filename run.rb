require "byebug"
require "./lib/preflop"
require "./lib/preflop_builder"
require "./lib/play"
require "./lib/player"
require "./lib/hand"

zoom_filenames = Dir["hand_histories_2018_06_04/*McNaught*.txt"] #[0...10]

hand_texts = []

zoom_filenames.each do |filename|
  data = File.read(filename, mode: "r:bom|utf-8").force_encoding("ASCII-8BIT")

  hand_texts += data.split("\n\n\n\n")
end

# only does 9-seat
def parse_players(player_lines)
  players = player_lines.map do |player_line|
    seat_num, username, stack_size = /\ASeat ([0-9]): (.+) \(\$([0-9.]+) in chips\)/.match(player_line).captures

    Player.new(username, seat_num.to_i, stack_size.to_f)
  end

  # button is now at the end - this needs to change if we ever do non-zoom hands
  players.rotate
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

  preflop = PreflopBuilder.new(preflop_lines, players_by_username).build

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

# print stats


def print_results(results)
  position_names = ["SB", "BB", "UTG", "UTG+1", "UTG+2", "MP", "HJ", "CO", "BTN"]
  position_names.zip(results).each do |position_name, result|
    prefix = "#{position_name}:".ljust(7)
    result_percentage = (result * 100).round(2)
    puts "#{prefix} #{result_percentage}%"
  end
  puts "\n"
end

seat_nums = [2, 3, 4, 5, 6, 7, 8, 9, 1]


puts "=== Open raise ==="
open_raise = seat_nums.map {|seat_num| hands.select{|hand| hand.preflop.open_raised?(seat_num)}.size / hands.select{|hand| hand.preflop.could_open?(seat_num)}.size.to_f }
print_results(open_raise)

puts "=== 3bets ==="
threebets = seat_nums.map {|seat_num| hands.select{|hand| hand.preflop.threebet?(seat_num)}.size / hands.select{|hand| hand.preflop.could_threebet?(seat_num)}.size.to_f }
print_results(threebets)

puts "=== Fold to 3bet ==="
foldtofourbet = seat_nums.map {|seat_num| hands.select{|hand| hand.preflop.fold_to_threebet?(seat_num)}.size / hands.select{|hand| hand.preflop.could_fourbet?(seat_num)}.size.to_f }
print_results(foldtofourbet)

puts "=== 4bets ==="
foldtofourbet = seat_nums.map {|seat_num| hands.select{|hand| hand.preflop.fourbet?(seat_num)}.size / hands.select{|hand| hand.preflop.could_fourbet?(seat_num)}.size.to_f }
print_results(foldtofourbet)

puts "=== Wins with open raise ==="
win_with_open_raise = seat_nums.map {|seat_num| hands.select{|hand| hand.preflop.won_with_open_raise?(seat_num)}.size / hands.select{|hand| hand.preflop.open_raised?(seat_num)}.size.to_f }
print_results(win_with_open_raise)

puts "=== BTN steal 3bet ==="
button_steals = hands.select {|hand| hand.preflop.open_raised?(1)}
sb_defends = button_steals.select {|hand| hand.preflop.threebet?(2)}
bb_defends = button_steals.select {|hand| hand.preflop.threebet?(3)}
puts "SB: #{(sb_defends.size.to_f / button_steals.size.to_f * 100).round(2)}% (#{sb_defends.size}/#{button_steals.size})"
puts "BB: #{(bb_defends.size.to_f / button_steals.size.to_f * 100).round(2)}% (#{bb_defends.size}/#{button_steals.size})"
button_folds_sb = sb_defends.select{|hand| hand.preflop.fold_to_threebet?(1) }
button_folds_bb = bb_defends.select{|hand| hand.preflop.fold_to_threebet?(1) }
puts "Button folds to SB: #{(button_folds_sb.size.to_f / sb_defends.size.to_f * 100).round(2)}% (#{button_folds_sb.size}/#{sb_defends.size})"
puts "Button folds to BB: #{(button_folds_bb.size.to_f / bb_defends.size.to_f * 100).round(2)}% (#{button_folds_bb.size}/#{bb_defends.size})"
button_fourbets_sb = sb_defends.select{|hand| hand.preflop.fourbet?(1) }
button_fourbets_bb = bb_defends.select{|hand| hand.preflop.fourbet?(1) }
puts "Button 4bets SB: #{(button_fourbets_sb.size.to_f / sb_defends.size.to_f * 100).round(2)}% (#{button_fourbets_sb.size}/#{sb_defends.size})"
puts "Button 4bets BB: #{(button_fourbets_bb.size.to_f / bb_defends.size.to_f * 100).round(2)}% (#{button_fourbets_bb.size}/#{bb_defends.size})"
puts "\n"

puts "=== SB steal 3bet ==="
sb_steals = hands.select {|hand| hand.preflop.open_raised?(2)}
bb_defends = sb_steals.select {|hand| hand.preflop.threebet?(3)}
puts "BB: #{(bb_defends.size.to_f / sb_steals.size.to_f * 100).round(2)}% (#{bb_defends.size}/#{sb_steals.size})"
sb_folds_bb = bb_defends.select{|hand| hand.preflop.fold_to_threebet?(2) }
puts "SB folds to BB: #{(sb_folds_bb.size.to_f / bb_defends.size.to_f * 100).round(2)}% (#{sb_folds_bb.size}/#{bb_defends.size})"
sb_fourbets_bb = bb_defends.select{|hand| hand.preflop.fourbet?(2) }
puts "SB 4bets BB: #{(sb_fourbets_bb.size.to_f / bb_defends.size.to_f * 100).round(2)}% (#{sb_fourbets_bb.size}/#{bb_defends.size})"
puts "\n"

#byebug
#puts "done"
