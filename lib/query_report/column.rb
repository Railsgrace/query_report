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
    #             options[:only_on_web] => the column will appear on the web and not appear in PDF or csv if set to true
    def column(name, options={}, &block)
      @columns << Column.new(self, name, options, block)
    end

    def column_total_with_colspan
      total_with_colspan = []
      colspan = 0
      total_text_printed = false
      columns.each do |column|
        if column.has_total?
          if colspan > 0
            title = total_text_printed ? '' : I18n.t('query_report.total')
            total_with_colspan << (colspan == 1 ? {content: title} : {content: title, colspan: colspan})
          end
          total_with_colspan << {content: column.total}
          total_text_printed = true
          colspan = 0
        else
          colspan += 1
        end
      end
      if colspan > 0
        total_with_colspan << {content: '', colspan: colspan}
      end
      total_with_colspan
    end

    class Column
      attr_reader :report, :name, :options, :type, :data

      def initialize(report, column_name, options={}, block = nil)
        @report, @name, @options = report, column_name, options
        @type = @report.model_class.columns_hash[column_name.to_s].try(:type) || options[:type] || :string
        @data = block || column_name.to_sym
      end

      def only_on_web?
        @options[:only_on_web] == true
      end

      def humanize
        @humanize ||= options[:as] || @report.model_class.human_attribute_name(name)
      end

      def value(record)
        self.data.kind_of?(Symbol) ? record.send(self.name) : self.data.call(record)
      end

      def has_total?
        @options[:show_total] == true
      end

      def total
        @total ||= has_total? ? report.filtered_query.sum(name) : nil
      end
    end
  end
end