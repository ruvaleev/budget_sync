# frozen_string_literal: true

class ExtractExpenses
  def call(parsed_data, input)
    result = fill_by_matched_categories(parsed_data, input)
    parsed_data.any? ? add_extra_categories(result, parsed_data) : result
  end

  private

  def fill_by_matched_categories(parsed_data, input)
    input.split("\n").map { |name| parsed_data.delete(name.strip)&.to_f }
  end

  def add_extra_categories(result, parsed_data)
    result << 'Не попавшие категории:'
    parsed_data.map { |name, value| result << "#{name}: #{value.to_f}" }

    result
  end
end
