# frozen_string_literal: true

class Expenses
  FILE_PATH = 'exports/export.csv'

  def call(input)
    export_file = CSV.read(FILE_PATH)
    parsed_data = ParseExport.new.call(export_file)
    ExtractExpenses.new.call(parsed_data, input)
  end
end
