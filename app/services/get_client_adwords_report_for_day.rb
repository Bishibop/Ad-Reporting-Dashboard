require 'adwords_api'

class GetClientAdwordsReportForDay

  def self.call(client, date)

    customer = client.customer

    adwords = AdwordsApi::Api.new({
      :authentication => {
          :method => 'OAuth2',
          :oauth2_client_id => ENV['ADWORDS_CLIENT_ID'],
          :oauth2_client_secret => ENV['ADWORDS_CLIENT_SECRET'],
          :oauth2_access_type => 'offline',
          :developer_token => ENV['ADWORDS_DEVELOPER_TOKEN'],
          :user_agent => 'Icarus Reporting',
          :oauth2_token => {
            access_token: customer.adwords_access_token,
            refresh_token: customer.adwords_refresh_token,
            issued_at: customer.adwords_issued_at,
            expires_in: customer.adwords_expires_in_seconds
          }
      },
      :service => {
        :environment => 'PRODUCTION'
      },
      :connection => {
        :enable_gzip => false
      },
      :library => {
        :log_level => 'INFO'
      }
    })

    report_utils = adwords.report_utils(:v201605)

    report_definition = {
      selector: {
        fields: [ 'Cost',
                  'Impressions',
                  'Ctr',
                  'Clicks',
                  'AllConversions',
                  'AllConversionRate',
                  'CostPerAllConversion',
                  'Conversions',
                  'ConversionRate',
                  'CostPerConversion',
                  'AverageCpc',
                  'AveragePosition' ],
        date_range: {
          min: date.strftime("%Y%m%d"),
          max: date.strftime("%Y%m%d")
        }
      },
      report_name: "#{customer.name} summary report - #{date}",
      report_type: 'ACCOUNT_PERFORMANCE_REPORT',
      download_format: 'CSV',
      date_range_type: "CUSTOM_DATE"
    }

    adwords.skip_report_header = true
    adwords.skip_column_header = true
    adwords.skip_report_summary = true
    adwords.include_zero_impressions = true

    csv_report = report_utils.download_report(report_definition, client.adwords_cid)

    CSV::Converters[:percent_to_float] = lambda do |field|
      if field.match(/^[\d\.]*%$/)
        field.chomp('%').to_f
      else
        field
      end
    end

    report_array = CSV.parse(csv_report, converters: [:numeric, :percent_to_float])[0]

    # this is really fragile.
    report_attributes = AdwordsReport.metric_names.zip(report_array).to_h

    # Can I have the model handle all of this? Like, what happens if I try and
    # just create a report with a preexisting date?
    # Or move this logic up into the date range report getting, so it won't
    # even make the request to google if It already has a report for the day
    existing_report = client.adwords_reports.find_by(date: date)
    if existing_report.nil?
      puts "\tCreating Adwords Report for #{client.name} - #{date}"
      client.adwords_reports.create(date: date, **report_attributes)
    else
      puts "\tUpdating Adwords Report for #{client.name} - #{date}"
      # Why are you updating anything here? If it already exists then it's not
      # going to change, right? BUT IT WILL. IF YOU GET A NEW REPORT FOR THE DAY OR
      # FOR A PREVIOUS DAY THAT YOU GOT HALFWAY THOUGH THAT DAY
      existing_report.update(report_attributes)
      existing_report
    end

  end

end
