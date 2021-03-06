require "pg_search/configuration/column"

module PgSearch
  class Configuration
    def initialize(options, model)
      options = options.reverse_merge(default_options)
      assert_valid_options(options)
      @options = options
      @model = model
    end

    def columns
      regular_columns + associated_columns
    end

    def regular_columns
      return [] unless @options[:against]
      Array(@options[:against]).map do |column_name, weight|
        Column.new(column_name, weight, @model)
      end
    end

    def associated_columns
      return [] unless @options[:associated_against]
      @options[:associated_against].map do |association, against|
        Array(against).map do |column_name, weight|
          Column.new(column_name, weight, @model, association)
        end
      end.flatten
    end

    def query
      @options[:query].to_s
    end

    def ignore
      Array.wrap(@options[:ignoring])
    end

    def ranking_sql
      @options[:ranked_by]
    end

    def features
      Array(@options[:using])
    end

    private

    def default_options
      {:using => :tsearch}
    end

    def assert_valid_options(options)
      valid_keys = [:against, :ranked_by, :ignoring, :using, :query, :associated_against]
      valid_values = {
        :ignoring => [:accents]
      }

      unless options[:against] || options[:associated_against]
        raise ArgumentError, "the search scope #{@name} must have :against#{" or :associated_against" if defined?(ActiveRecord::Relation)} in its options"
      end
      raise ArgumentError, ":associated_against requires ActiveRecord 3 or later" if options[:associated_against] && !defined?(ActiveRecord::Relation)

      options.assert_valid_keys(valid_keys)

      valid_values.each do |key, values_for_key|
        Array.wrap(options[key]).each do |value|
          unless values_for_key.include?(value)
            raise ArgumentError, ":#{key} cannot accept #{value}"
          end
        end
      end
    end
  end
end
