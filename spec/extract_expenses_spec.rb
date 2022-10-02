# frozen_string_literal: true

RSpec.describe ExtractExpenses do # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:result) { described_class.new.call(parsed_export, input) }

  let(:parsed_export) do
    {
      'Счета (Living)' => bills,
      'Аренда, но с другим именем (Living)' => rent,
      'Повседневные (Daily)' => daily,
      'Подписки (Subscriptions)' => subscriptions,
      'Вне бюджета (Out of scope)' => out_of_scope,
      'Прочее (Other)' => other,
      'Бензин (Transport)' => gas,
      'Телефон (Phone)' => phone
    }
  end
  let(:bills) { BigDecimal(rand(1_000).to_s) }
  let(:daily) { BigDecimal(rand(1_000).to_s) }
  let(:subscriptions) { BigDecimal(rand(1_000).to_s) }
  let(:out_of_scope) { BigDecimal(rand(1_000).to_s) }
  let(:other) { BigDecimal(rand(1_000).to_s) }
  let(:gas) { BigDecimal(rand(1_000).to_s) }
  let(:rent) { BigDecimal(rand(1_000).to_s) }
  let(:phone) { BigDecimal(rand(1_000).to_s) }
  let(:input) do
    "Счета (Living)

    Повседневные (Daily)
    Visa Questions
    Health
    Подписки (Subscriptions)
    Телефон (Phone)

    Бензин (Transport)


    Жилье временное (Living)
    Спортзал (Other)

    Прочее (Other)

    Tickets somewhere
    Медицинские и пр расходы"
  end
  let(:expected_result) do
    [
      bills.to_f,
      nil,
      daily.to_f,
      nil,
      nil,
      subscriptions.to_f,
      phone.to_f,
      nil,
      gas.to_f,
      nil,
      nil,
      nil,
      nil,
      nil,
      other.to_f,
      nil,
      nil,
      nil,
      'Не попавшие категории:',
      "Аренда, но с другим именем (Living): #{rent.to_f}",
      "Вне бюджета (Out of scope): #{out_of_scope.to_f}"
    ]
  end

  it 'returns expenses properly splitted by categories and in proper order' do
    expect(result).to eq(expected_result)
  end
end
