require 'query_report/filter_module/dsl'

module QueryReport
  autoload :ColumnModule, 'query_report/column'
  autoload :PaginateModule, 'query_report/paginate'
  autoload :Record, 'query_report/record'
  autoload :ChartAdapterModule, 'query_report/chart_adapter'

  DEFAULT_OPTIONS = {enable_chart: true, chart_on_web: true, chart_on_pdf: true, paginate: true}

  class Report
    attr_reader :params, :template, :options, :charts

    include QueryReport::FilterModule::DSL
    include QueryReport::ColumnModule
    include QueryReport::PaginateModule
    include QueryReport::Record
    include QueryReport::ChartAdapterModule

    def initialize(params, template, options={}, &block)
      @params, @template = params, template
      @columns, @filters, @charts = [], [], []
      @options = QueryReport::DEFAULT_OPTIONS.merge options
      instance_eval &block if block_given?
    end

    # define options methods
    QueryReport::DEFAULT_OPTIONS.each do |option_name, value|
      if value.class == TrueClass or value.class == FalseClass
        define_method "#{option_name.to_s}?" do
          @options[option_name]
        end
      end
    end

    def has_chart?
      !@charts.empty?
    end

    def has_total?
      @columns.any?(&:has_total?)
    end

    def paginate?
      return false if array_record? #do not paginate on the array records
      return true if @options[:paginate].nil?
      @options[:paginate]
    end

    # to support the helper methods
    def method_missing(meth, *args, &block)
      if @template.respond_to?(meth)
        @template.send(meth, *args)
      else
        super
      end
    end
  end
end