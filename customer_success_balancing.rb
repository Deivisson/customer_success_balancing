require 'minitest/autorun'
require 'timeout'


class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute ## O(n + n) - time complexity
    prepare_data
    index_cs          = index_customer_success_to_start
    current_cs        = @customer_success[index_cs] unless index_cs.nil?
    current_customer  = nil
    index_customer    = 0
    greather_count    = 0
    overworked_id     = 0
    balancing         = {}

    # All CS have a level smaller than the size of the Clients,
    # consequently all clients are not supported
    return 0 if current_cs.nil?

    while (index_customer < @customers.size) do # O(n)
      current_customer        = @customers[index_customer]
      current_customer_score  = current_customer[:score]
      current_cs_score        = current_cs[:score]
      
      # If the current customer score greater than current CS score,
      # move to the next CS. This is possible because the CSS are in sorted
      if current_customer_score > current_cs_score then
        index_cs += 1
        current_cs = @customer_success[index_cs]

        # Customers with sizes greater than the levels of possible CSs...
        # For this scenario, there will be customers without compatible CSs
        break if (!current_cs) 
      end

      if current_cs_score >= current_customer_score then
        current_cs_id             = current_cs[:id]
        balancing[current_cs_id]  = balancing[current_cs_id].nil? ? 1 : balancing[current_cs_id] + 1

        if balancing[current_cs_id] > greather_count then
          greather_count = balancing[current_cs_id]
          overworked_id  = current_cs_id
        elsif balancing[current_cs_id] == greather_count && overworked_id != current_cs_id then
          # The first time it finds the same count for more than one CS,
          # It breaks the loop and returns as a tie 
          overworked_id = 0 
          break;
        end
        index_customer += 1
      end
    end
    overworked_id
  end

  private

  # Sorting data and removing the aways CSS
  # This actions will allow the main method be a linear
  def prepare_data
    @customers        = @customers.sort_by{|k| k[:score]}
    @customer_success = @customer_success
                          .sort_by{|k| k[:score]}
                          .delete_if {|cs| @away_customer_success.include?(cs[:id])}
  end
  
  # Return the CSs index that has possibility to attend customers
  def index_customer_success_to_start
    first_customer = @customers[0];
    @customer_success.each_with_index do |cs, index|
      return index if cs[:score] >= first_customer[:score]
    end
    return nil
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([50, 100]),
      build_scores([20, 30, 35, 40, 60, 80]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
