# frozen_string_literal: true

require 'csv'
require 'bigdecimal'

class ParseExport
  CATEGORY_FIELD_INDEX = 3
  DATE_FIELD_INDEX = 0
  TYPE_FIELD_INDEX = 1
  USD_VALUE_FIELD_INDEX = 7

  def call(parsed_csv)
    parsed_csv.each_with_object(Hash.new(0)) do |row, result|
      add_to_result(row, result)
    end
  end

  private

  def add_to_result(row, result)
    return unless expense_record?(row)

    category = row[CATEGORY_FIELD_INDEX]
    result[category] += BigDecimal(row[USD_VALUE_FIELD_INDEX].gsub(',', '.'))
  end

  def expense_record?(row)
    row[DATE_FIELD_INDEX].to_s.match?(/^\d{2}\.\d{2}\.\d{4}/) && row[TYPE_FIELD_INDEX] == 'Расход'
  end
end
