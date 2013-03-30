require 'query_report/filter'
require 'query_report/column'
require 'query_report/chart/basic_chart'
require 'query_report/chart/chart_with_total'

module QueryReport
  class Record
    attr_accessor :params, :query, :query_without_pagination, :chart,
                  :filters, :search, :scopes, :current_scope

    def initialize(params, options={}, &block)
      @params = params
      @columns = []
      @filters = []
      @scopes = []
      @column_separator = options.delete(:separator)
      @current_scope = @params[:scope] || 'all'
      @options = options.delete(:options)
      instance_eval &block if block_given?
    end

    def column(name, options={}, &block)
      @columns << Column.new(name, options, block)
    end

    def set_query(query)
      @query_cache = query
      #apply ransack
      @search = query.search(@params[:q])
      @query_cache = @search.result
    end

    def columns
      @columns
    end

    def column_names
      @column_names ||= (@columns||[]).collect(&:humanize)
    end

    def query
      apply_filters_and_pagination
      @query_cache
    end

    def query_without_pagination
      apply_filters_and_pagination
      @query_without_pagination_cache
    end

    def records
      @cached_records ||= map_record(query)
    end

    def all_records
      @cached_all_records ||= map_record(query_without_pagination)
    end

    def map_record(query)
      query.clone.map do |record|
        array = @columns.collect { |column| [column.humanize,
                                             (column.data.kind_of?(Symbol) ? record.send(column.name) : column.data.call(record))] }
        Hash[*array.flatten]
      end
    end

    def filter(column, options, &block)
      @filters << Filter.new(column, options, &block)
    end

    def column_chart(title, columns)
      @chart = QueryReport::Chart::BasicChart.new(:column, title, columns, all_records)
    end

    def compare_with_column_chart(title, x_axis, &block)
      @chart = QueryReport::Chart::CustomChart.new(:column, title, query_without_pagination)
      @chart.add_column x_axis
      @chart.instance_eval &block if block_given?
    end

    def pie_chart(title, &block)
      @chart = QueryReport::Chart::PieChart.new(title, query_without_pagination)
      @chart.instance_eval &block if block_given?
    end

    def pie_chart_on_total(title, columns)
      @chart = QueryReport::Chart::ChartWithTotal.new(:pie, title, columns, all_records, {:is3D => true})
    end

    def scope(scope)
      @scopes << scope
      @scopes = @scopes.uniq
    end

    private
    def apply_filters_and_pagination
      return if @applied_filters_and_pagination
      if @current_scope and !['all', 'delete_all', 'destroy_all'].include?(@current_scope)
        @query_cache = @query_cache.send(@current_scope)
      end

      @filters.each do |filter|
        if filter.custom
          param = @params[:custom_search]
          #Rails.logger.debug "@params[:custom_search] :: #{@params[:custom_search].inspect}"
          #Rails.logger.debug "param :: #{param.inspect}"
          first_val = param[filter.keys.first] rescue nil
          last_val = param[filter.keys.last] rescue nil
          case filter.keys.size
            when 1
              @query_cache = filter.block.call(@query_cache, first_val) if first_val.present?
              break
            when 2
              @query_cache = filter.block.call(@query_cache, first_val, last_val) if first_val.present? and last_val.present?
              break
          end
        end
      end
      @query_without_pagination_cache = @query_cache
      @query_cache = @query_without_pagination_cache.page(@params[:page])
      @applied_filters_and_pagination = true
    end
  end
end