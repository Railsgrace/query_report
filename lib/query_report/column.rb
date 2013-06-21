# Author::    A.K.M. Ashrafuzzaman  (mailto:ashrafuzzaman.g2@gmail.com)
# License::   MIT-LICENSE

# The purpose of the column module is to define columns that are displayed in the views

module QueryReport
  module ColumnModule
    attr_accessor :columns

    # Creates a filter and adds to the filters
    # Params:
    # +column+:: the column on which the filter is done on
    # +options+:: Options can have the following,
    #             options[:type] => date | text | whatever
    #             options[:comp] => the comparators used for ransack search, [:gteq, :lteq]
    def column(name, options={}, &block)
      @columns << Column.new(self, name, options, block)
    end

    class Column
      attr_reader :report, :name, :options, :type, :data

      def initialize(report, column_name, options={}, block = nil)
        @report = report
        @name = column_name
        @options = options

        @type = @report.model_class.columns_hash[column_name.to_s].try(:type) || :string
        @data = block || column_name.to_sym
      end

      def humanize
        options[:as] || @report.model_class.human_attribute_name(name)
      end
    end
  end
end