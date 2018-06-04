require "./lib/preflop"

describe Preflop do
  let(:preflop) { Preflop.new(plays) }

  context "When UTG raises" do
    let(:plays) {
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
        expect(preflop.could_open?(0)).to be true
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be false
        expect(preflop.could_open?(4)).to be false
        expect(preflop.could_open?(5)).to be false
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.could_open?(0)).to be true
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be false
        expect(preflop.could_open?(4)).to be false
        expect(preflop.could_open?(5)).to be false
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
      end
    end
  end

  context "When UTG limps" do
    let(:plays) {
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
        expect(preflop.could_open?(0)).to be true
        expect(preflop.could_open?(1)).to be false
        expect(preflop.could_open?(2)).to be false
        expect(preflop.could_open?(3)).to be false
        expect(preflop.could_open?(4)).to be false
        expect(preflop.could_open?(5)).to be false
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.open_raised?(0)).to be false
        expect(preflop.open_raised?(1)).to be false
        expect(preflop.open_raised?(2)).to be false
        expect(preflop.open_raised?(3)).to be false
        expect(preflop.open_raised?(4)).to be false
        expect(preflop.open_raised?(5)).to be false
        expect(preflop.open_raised?(6)).to be false
        expect(preflop.open_raised?(7)).to be false
        expect(preflop.open_raised?(8)).to be false
      end
    end
  end

  context "When everyone folds" do
    let(:plays) {
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
        expect(preflop.could_open?(0)).to be true
        expect(preflop.could_open?(1)).to be true
        expect(preflop.could_open?(2)).to be true
        expect(preflop.could_open?(3)).to be true
        expect(preflop.could_open?(4)).to be true
        expect(preflop.could_open?(5)).to be true
        expect(preflop.could_open?(6)).to be true
        expect(preflop.could_open?(7)).to be true
        expect(preflop.could_open?(8)).to be true
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.open_raised?(0)).to be false
        expect(preflop.open_raised?(1)).to be false
        expect(preflop.open_raised?(2)).to be false
        expect(preflop.open_raised?(3)).to be false
        expect(preflop.open_raised?(4)).to be false
        expect(preflop.open_raised?(5)).to be false
        expect(preflop.open_raised?(6)).to be false
        expect(preflop.open_raised?(7)).to be false
        expect(preflop.open_raised?(8)).to be false
      end
    end
  end

  context "When UTG+2 raises" do
    let(:plays) {
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
        expect(preflop.could_open?(0)).to be true
        expect(preflop.could_open?(1)).to be true
        expect(preflop.could_open?(2)).to be true
        expect(preflop.could_open?(3)).to be false
        expect(preflop.could_open?(4)).to be false
        expect(preflop.could_open?(5)).to be false
        expect(preflop.could_open?(6)).to be false
        expect(preflop.could_open?(7)).to be false
        expect(preflop.could_open?(8)).to be false
      end
    end

    describe "#open_raised?" do
      it "is correct for each position" do
        expect(preflop.open_raised?(0)).to be false
        expect(preflop.open_raised?(1)).to be false
        expect(preflop.open_raised?(2)).to be true
        expect(preflop.open_raised?(3)).to be false
        expect(preflop.open_raised?(4)).to be false
        expect(preflop.open_raised?(5)).to be false
        expect(preflop.open_raised?(6)).to be false
        expect(preflop.open_raised?(7)).to be false
        expect(preflop.open_raised?(8)).to be false
      end
    end
  end
end