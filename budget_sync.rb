# frozen_string_literal: true

class BudgetSync
  attr_accessor :currency_rates, :to_increase, :to_reduce, :result_recommendations

  def initialize(currency_rates)
    @currency_rates = currency_rates
    @to_increase = currency_rates.transform_values { [] }
    @to_reduce = currency_rates.transform_values { [] }
    @result_recommendations = []
  end

  def directions(accounts)
    choose_accounts_for_correction(accounts)
    collect_directions_for_same_currency_accounts
    collect_directions_for_different_currencies_accounts
    collection_directions_for_balance_correction_transactions

    complete
  end

  private

  def choose_accounts_for_correction(accounts)
    accounts.each do |account|
      validate_currency_correctness(account[:currency])
      next if account[:value_in_app] == account[:value_in_real]

      move_to_increase_or_to_decrease(account, account[:currency])
    end
  end

  def validate_currency_correctness(currency)
    raise "unknown currency - #{currency}" unless to_increase.key?(currency)
  end

  def move_to_increase_or_to_decrease(account, currency)
    goal_array = account[:value_in_app] < account[:value_in_real] ? to_increase : to_reduce
    goal_array[currency] << {
      name: account[:name],
      currency: currency,
      value: (account[:value_in_real] - account[:value_in_app]).abs
    }
  end

  def collect_directions_for_same_currency_accounts
    to_reduce.each do |currency, accounts_to_reduce|
      accounts_to_increase = to_increase[currency]
      next if accounts_to_increase.empty?

      accounts_to_reduce.each do |account_to_reduce|
        correct_accounts(account_to_reduce, accounts_to_increase)
      end
    end
  end

  def collect_directions_for_different_currencies_accounts
    accounts_to_increase = to_increase.values.flatten.filter { |account| (account[:value]).positive? }
    to_reduce.values.flatten.filter { |account| (account[:value]).positive? }.each do |account_to_reduce|
      correct_accounts(account_to_reduce, accounts_to_increase, with_currency_exchange: true)
    end
  end

  def collection_directions_for_balance_correction_transactions
    non_zero_accounts(to_reduce).each { |account| balance_correction_recommendation(account, 'expense') }
    non_zero_accounts(to_increase).each { |account| balance_correction_recommendation(account, 'income') }
  end

  def non_zero_accounts(accounts_list)
    accounts_list.values.flatten.filter { |account| (account[:value]).positive? }
  end

  def correct_accounts(account_to_reduce, accounts_to_increase, with_currency_exchange: false)
    accounts_to_increase.each do |account_to_increase|
      break if account_to_reduce[:value].zero?
      next if account_to_increase[:value].zero?

      amount_to_reduce, amount_to_increase =
        correction_amounts(account_to_reduce, account_to_increase, with_currency_exchange)

      account_to_reduce[:value] -= amount_to_reduce
      account_to_increase[:value] -= amount_to_increase

      transfer_recommendation(account_to_reduce, amount_to_reduce, account_to_increase, amount_to_increase)
    end
  end

  def correction_amounts(account_to_reduce, account_to_increase, with_currency_exchange)
    if with_currency_exchange
      amount_to_adjust = [normalized_value(account_to_reduce), normalized_value(account_to_increase)].min
      amount_to_reduce = amount_to_adjust * account_rate(account_to_reduce)
      amount_to_increase = amount_to_adjust * account_rate(account_to_increase)
    else
      amount_to_reduce = amount_to_increase = [account_to_reduce[:value], account_to_increase[:value]].min
    end
    [amount_to_reduce, amount_to_increase]
  end

  def normalized_value(account)
    BigDecimal(account[:value].to_s) / account_rate(account)
  end

  def account_rate(account)
    currency_rates[account[:currency]]
  end

  def transfer_recommendation(account_to_reduce, amount_to_reduce, account_to_increase, amount_to_increase)
    result_recommendations << I18n.t(
      'recommendations.transfer',
      reduction_account: account_to_reduce[:name],
      reduction_amount: format('%.2f', amount_to_reduce),
      reduction_currency: account_to_reduce[:currency],
      increasion_account: account_to_increase[:name],
      increasion_amount: format('%.2f', amount_to_increase),
      increasion_currency: account_to_increase[:currency]
    )
  end
end

def balance_correction_recommendation(account, key)
  result_recommendations << I18n.t(
    "recommendations.#{key}",
    account: account[:name],
    amount: format('%.2f', account[:value]),
    currency: account[:currency]
  )
end

def complete
  result_recommendations << I18n.t(:completed)
  result_recommendations
end
