class UpdateProbabilityWeights < ActiveRecord::Migration
  def up
    DecisionUserReputation.find_each do |dur|
      dur.update_probability_right
    end
  end

  def down
  end
end
