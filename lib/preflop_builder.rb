class PreflopBuilder
  def initialize(preflop_lines, players_by_username)
    @preflop_lines = preflop_lines
    @players_by_username = players_by_username
  end

  def build()
    hole_card_line = @preflop_lines.shift
    raise "Bad hole card line: #{hole_card_line}" unless /Dealt to .+ \[(.. ..)\]/.match(hole_card_line)
    hole_cards = $1

    # filter junk lines

    @preflop_lines = @preflop_lines.reject do |preflop_line|
      /has timed out/.match(preflop_line) ||
        /is disconnected/.match(preflop_line) ||
        /is connected/.match(preflop_line) ||
        /said, ".+"/.match(preflop_line)
    end

    if @preflop_lines.any? { |line| /collected \$[0-9.]+ from pot/.match(line) }
      #won at flop
      winning_lines = @preflop_lines.pop(2)
      raise "Preflop winning line fail: #{@preflop_lines} #{winning_lines}" unless /collected \$[0-9.]+ from pot/.match(winning_lines[0])
    end

    plays = @preflop_lines.flat_map do |preflop_line|
      if /(.+): raises \$([0-9.]+) to \$([0-9.]+)/.match(preflop_line)
        Play.new(:raise, @players_by_username[$1], $2.to_f, $3.to_f)
      elsif /(.+): calls \$([0-9.]+)/.match(preflop_line)
        Play.new(:call, @players_by_username[$1], 0.0, $2.to_f)
      elsif /(.+): folds/.match(preflop_line)
        Play.new(:fold, @players_by_username[$1], 0.0, nil)
      elsif /(.+): checks/.match(preflop_line)
        Play.new(:check, @players_by_username[$1], 0.0, nil)
      elsif /\AUncalled bet \(\$([0-9.]+)\) returned to (.+)/.match(preflop_line)
        Play.new(:extra_returned, @players_by_username[$2], -$1.to_f, nil)
      else
        raise "Unrecognised preflop play: #{preflop_line}"
      end
    end

    Preflop.new(plays, hole_cards)
  end
end
