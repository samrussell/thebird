require "./lib/preflop"
require "./lib/play"
require "./lib/player"

describe Preflop do
  let(:preflop) { Preflop.new(plays, "As Ac") }
  let(:players) { [3, 4, 5, 6, 7, 8, 9, 1, 2].map { |seat_num| Player.new(nil, seat_num, nil) } }
  let(:plays) { play_types.zip(players).map { |play_type, player| Play.new(play_type, player, nil, nil) } }

  context "When UTG raises" do
    let(:play_types) {
      [
        :raise,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
      ]
    }

    describe "#could_open?" do
      it "is correct for each position" do
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be true
        expect(preflop.could_open?(4)).to be false
        expect(preflop.could_open?(5)).to be false
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
        expect(preflop.could_open?(9)).to be false
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be true
        expect(preflop.could_open?(4)).to be false
        expect(preflop.could_open?(5)).to be false
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
        expect(preflop.could_open?(9)).to be false
      end
    end
  end

  context "When UTG limps" do
    let(:play_types) {
      [
        :call,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
      ]
    }

    describe "#could_open?" do
      it "is correct for each position" do
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be true
        expect(preflop.could_open?(4)).to be false
        expect(preflop.could_open?(5)).to be false
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
        expect(preflop.could_open?(8)).to be false
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.open_raised?(1)).to be false
        expect(preflop.open_raised?(2)).to be false
        expect(preflop.open_raised?(3)).to be false
        expect(preflop.open_raised?(4)).to be false
        expect(preflop.open_raised?(5)).to be false
        expect(preflop.open_raised?(6)).to be false
        expect(preflop.open_raised?(7)).to be false
        expect(preflop.open_raised?(8)).to be false
        expect(preflop.open_raised?(9)).to be false
      end
    end
  end

  context "When everyone folds" do
    let(:play_types) {
      [
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
      ]
    }

    describe "#could_open?" do
      it "is correct for each position" do
        expect(preflop.could_open?(1)).to be true
        # this might not be the case for BB but depends what stats we want
        expect(preflop.could_open?(2)).to be true
        expect(preflop.could_open?(3)).to be true
        expect(preflop.could_open?(4)).to be true
        expect(preflop.could_open?(5)).to be true
        expect(preflop.could_open?(6)).to be true
        expect(preflop.could_open?(7)).to be true
        expect(preflop.could_open?(8)).to be true
        expect(preflop.could_open?(9)).to be true
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.open_raised?(1)).to be false
        expect(preflop.open_raised?(2)).to be false
        expect(preflop.open_raised?(3)).to be false
        expect(preflop.open_raised?(4)).to be false
        expect(preflop.open_raised?(5)).to be false
        expect(preflop.open_raised?(6)).to be false
        expect(preflop.open_raised?(7)).to be false
        expect(preflop.open_raised?(8)).to be false
        expect(preflop.open_raised?(9)).to be false
      end
    end
  end

  context "When UTG+2 raises" do
    let(:play_types) {
      [
        :fold,
        :fold,
        :raise,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
        :fold,
      ]
    }

    describe "#could_open?" do
      it "is correct for each position" do
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be true
        expect(preflop.could_open?(4)).to be true
        expect(preflop.could_open?(5)).to be true
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
        expect(preflop.could_open?(9)).to be false
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.open_raised?(1)).to be false
        expect(preflop.open_raised?(2)).to be false
        expect(preflop.open_raised?(3)).to be false
        expect(preflop.open_raised?(4)).to be false
        expect(preflop.open_raised?(5)).to be true
        expect(preflop.open_raised?(6)).to be false
        expect(preflop.open_raised?(7)).to be false
        expect(preflop.open_raised?(8)).to be false
        expect(preflop.open_raised?(9)).to be false
      end
    end
  end

  context "With IP 3bet" do
    let(:play_types) {
      [
        :fold,
        :fold,
        :fold,
        :raise,
        :fold,
        :fold,
        :raise,
        :fold,
        :fold,
      ]
    }

    describe "#could_open?" do
      it "is correct for each position" do
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be true
        expect(preflop.could_open?(4)).to be true
        expect(preflop.could_open?(5)).to be true
        expect(preflop.could_open?(6)).to be true
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
        expect(preflop.could_open?(9)).to be false
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.open_raised?(1)).to be false
        expect(preflop.open_raised?(2)).to be false
        expect(preflop.open_raised?(3)).to be false
        expect(preflop.open_raised?(4)).to be false
        expect(preflop.open_raised?(5)).to be false
        expect(preflop.open_raised?(6)).to be true
        expect(preflop.open_raised?(7)).to be false
        expect(preflop.open_raised?(8)).to be false
        expect(preflop.open_raised?(9)).to be false
      end
    end

    describe "#could_threebet?" do
      it "is correct for each position" do
        expect(preflop.could_threebet?(1)).to be false
        expect(preflop.could_threebet?(2)).to be false
        expect(preflop.could_threebet?(3)).to be false
        expect(preflop.could_threebet?(4)).to be false
        expect(preflop.could_threebet?(5)).to be false
        expect(preflop.could_threebet?(6)).to be false
        expect(preflop.could_threebet?(7)).to be true
        expect(preflop.could_threebet?(8)).to be true
        expect(preflop.could_threebet?(9)).to be true
      end
    end

    describe "#threebet?" do
      it "is correct for each position" do
        expect(preflop.threebet?(1)).to be false
        expect(preflop.threebet?(2)).to be false
        expect(preflop.threebet?(3)).to be false
        expect(preflop.threebet?(4)).to be false
        expect(preflop.threebet?(5)).to be false
        expect(preflop.threebet?(6)).to be false
        expect(preflop.threebet?(7)).to be false
        expect(preflop.threebet?(8)).to be false
        expect(preflop.threebet?(9)).to be true
      end
    end
  end
end