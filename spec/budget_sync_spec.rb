# frozen_string_literal: true

RSpec.describe BudgetSync do
  subject(:result) { described_class.new(currency_rates).directions(accounts) }

  let(:currency_rates) { { THB: 32, RUB: 81 } }
  let(:accounts) { [{ name: 'Thai Wallet', currency: :THB, value_in_app: 1, value_in_real: 1 }] }

  context 'when accounts with same currency can exchange funds' do
    let(:accounts) do
      [
        { name: 'Thai Wallet', currency: :THB, value_in_app: 3_171.25, value_in_real: 2_000 },
        { name: 'Safe Vault THB', currency: :THB, value_in_app: 2000, value_in_real: 3_171.25 }
      ]
    end

    it 'returns correct recommendations about transfer from one account to another' do
      expect(result).to eq(
        [
          I18n.t(
            'recommendations.transfer',
            reduction_account: 'Thai Wallet',
            reduction_amount: '1171.25',
            reduction_currency: 'THB',
            increasion_account: 'Safe Vault THB',
            increasion_amount: '1171.25',
            increasion_currency: 'THB'
          ),
          I18n.t(:completed)
        ]
      )
    end
  end

  context 'when accounts with different currencies must exchange funds' do
    let(:accounts) do
      [
        { name: 'Thai Wallet', currency: :THB, value_in_app: 2000, value_in_real: 0 },
        { name: 'Debts account', currency: :RUB, value_in_app: 10_000, value_in_real: 15_062.5 }
      ]
    end

    it 'returns directions according to provided currencies' do
      expect(result).to eq(
        [
          I18n.t(
            'recommendations.transfer',
            reduction_account: 'Thai Wallet',
            reduction_amount: '2000.00',
            reduction_currency: 'THB',
            increasion_account: 'Debts account',
            increasion_amount: '5062.50',
            increasion_currency: 'RUB'
          ),
          I18n.t(:completed)
        ]
      )
    end
  end

  context 'when exchange is not enough for correction' do
    let(:higher_value) { rand(1..10) }

    context 'when value in real is higher' do
      let(:accounts) { [{ name: 'Thai Wallet', currency: :THB, value_in_app: 0, value_in_real: higher_value }] }

      it 'returns recommendations to apply income correction transaction' do
        expect(result).to eq(
          [
            I18n.t('recommendations.income', account: 'Thai Wallet', amount: "#{higher_value}.00", currency: 'THB'),
            I18n.t(:completed)
          ]
        )
      end
    end

    context 'when value in app is higher' do
      let(:accounts) { [{ name: 'Thai Wallet', currency: :THB, value_in_app: higher_value, value_in_real: 0 }] }

      it 'returns recommendations to apply expense correction transaction' do
        expect(result).to eq(
          [
            I18n.t('recommendations.expense', account: 'Thai Wallet', amount: "#{higher_value}.00", currency: 'THB'),
            I18n.t(:completed)
          ]
        )
      end
    end
  end

  context 'when some of provided accounts have inappropriate currency' do
    let(:accounts) { [{ name: 'Thai Wallet', currency: :UNEXISTING, value_in_app: 1, value_in_real: 0 }] }

    it 'raises error about inappropriate currency' do
      expect { result }.to raise_error(StandardError, 'unknown currency - UNEXISTING')
    end
  end
end
