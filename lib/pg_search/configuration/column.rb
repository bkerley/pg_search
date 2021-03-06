module PgSearch
  class Configuration
    class Column
      attr_reader :weight, :association

      def initialize(column_name, weight, model, association = nil)
        @column_name = column_name.to_s
        @weight = weight
        @model = model
        @association = association
      end

      def table
        foreign? ? @model.reflect_on_association(association).table_name : @model.table_name
      end

      def full_name
        "#{@model.connection.quote_table_name(table)}.#{@model.connection.quote_column_name(@column_name)}"
      end

      def to_sql
        name = if foreign?
                 "#{self.subselect_alias}.#{self.alias}"
               else
                 full_name
               end
        "coalesce(#{name}, '')"
      end

      def foreign?
        @association.present?
      end

      def alias
        ["pg_search", table, association, @column_name].compact.join('_')
      end

      def subselect_alias
        "#{self.alias}_subselect"
      end
    end
  end
end
