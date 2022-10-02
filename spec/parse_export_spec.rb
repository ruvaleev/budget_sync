# frozen_string_literal: true

RSpec.describe ParseExport do
  subject(:result) { described_class.new.call(file) }

  let(:file) { CSV.read('spec/fixtures/export.csv') }
  let(:expected_result) do
    {
      'Повседневные (Daily)' => BigDecimal('255.98'),
      'Подписки (Subscriptions)' => BigDecimal('27'),
      'Вне бюджета (Out of scope)' => BigDecimal('1072.89'),
      'Прочее (Other)' => BigDecimal('121.42'),
      'Бензин (Gas)' => BigDecimal('7'),
      'Телефон (Phone)' => BigDecimal('12')
    }
  end

  it { is_expected.to eq(expected_result) }
end
