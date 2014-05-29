# Author::    A.K.M. Ashrafuzzaman  (mailto:ashrafuzzaman.g2@gmail.com)
# License::   MIT-LICENSE

# The purpose of the helper module is to help controllers with the responders

require 'csv'
require 'query_report/report'
require 'query_report/report_pdf'

module QueryReport
  module Helper

    # Generates the reports
    # Params:
    # query - The base query that the reporter with start with [filters will be applied on it]
    # options - Options for the reports
    #           :per_page - If given then overrides the default kaminari per page option
    #           :custom_view - by default false, if set to true then the reporter will look for the file to render
    #           :skip_rendering - by default false, if set to true then the reporter will not render any thing, you will have to implement the rendering
    def reporter(query, options={}, &block)
      @report ||= QueryReport::Report.new(params, view_context, options)
      @report.query = query
      @report.instance_eval &block
      render_report(options) unless options[:skip_rendering]
      @report
    end

    def render_report(options)
      if (params[:send_as_email].to_i > 0)
        send_pdf_email(params[:email_to], params[:subject], params[:message], action_name, pdf_for_report(options))
      end

      @remote = false
      respond_to do |format|
        if options[:custom_view]
          format.js do
            @remote = true
          end
          format.html
        else
          format.js do
            @remote = true
            render 'query_report/list'
          end
          format.html { render('query_report/list') }
        end
        format.json { render json: @report.all_records }
        format.csv { send_data generate_csv_for_report(@report.all_records), :disposition => "attachment;" }
        format.pdf { send_data pdf_for_report(options), :type => 'application/pdf', :disposition => 'inline' }
      end
    end

    def pdf_for_report(options)
      query_report_pdf_template_class(options).new(@report).to_pdf.render
    end

    def query_report_pdf_template_class(options)
      options = QueryReport.config.pdf_options.merge(options)
      if options[:template_class]
        @template_class ||= options[:template_class].to_s.constantize
        return @template_class
      end
      QueryReport::ReportPdf
    end

    def generate_csv_for_report(records)
      if records.size > 0
        columns = records.first.keys
        CSV.generate do |csv|
          csv << columns
          records.each do |record|
            csv << record.values.collect { |val| val.kind_of?(String) ? view_context.strip_links(val) : val }
          end
        end
      else
        nil
      end
    end

    def send_pdf_email(email, subject, message, file_name, attachment)
      @user = current_user
      to = email.split(',')
      ReportMailer.send_report(@user, to, subject, message, file_name, attachment).deliver
    end
  end
end