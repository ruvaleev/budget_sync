# frozen_string_literal: true

RSpec.describe Expenses do # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:result) { described_class.new.call(input) }

  let(:input) do
    "Счета (Living)
    Повседневные (Daily)"
  end
  let(:parsed_export) do
    {
      'Счета (Living)' => bills,
      'Повседневные (Daily)' => daily
    }
  end
  let(:bills) { BigDecimal(rand(1_000).to_s) }
  let(:daily) { BigDecimal(rand(1_000).to_s) }
  let(:expected_result) { [bills.to_f, daily.to_f] }
  let(:parse_export_double) { instance_double(ParseExport) }
  let(:extract_expenses_double) { instance_double(ExtractExpenses) }

  before do
    allow(ParseExport).to receive(:new).and_return(parse_export_double)
    allow(parse_export_double).to receive(:call).and_return(parsed_export)
  end

  it { is_expected.to eq(expected_result) }

  it 'parses file /exports/export.csv' do
    result
    expect(parse_export_double).to have_received(:call).once
  end

  it 'extracts expenses from parsed file' do
    allow(ExtractExpenses).to receive(:new).and_return(extract_expenses_double)
    allow(extract_expenses_double).to receive(:call).with(parsed_export, input)
    result
    expect(extract_expenses_double).to have_received(:call).with(parsed_export, input).once
  end
end
