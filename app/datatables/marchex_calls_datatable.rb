class MarchexCallsDatatable
  delegate :params, to: :@view

  def initialize(view, client)
    @view = view
    @client = client
  end

  def as_json(options = {})
    {
      draw: params[:draw].to_i,
      recordsTotal: @client.marchex_call_records.count,
      recordsFiltered: marchex_calls.total_entries,
      data: data
    }
  end

private

  def data
    marchex_calls.map do |call|
      [ call.caller_name,
        call.caller_number,
        call.campaign,
        call.group_name,
        call.start_time,
        call.pretty_duration,
        call.status,
        call.playback_url ]
    end
  end

  def marchex_calls
    @marchex_calls ||= fetch_marchex_calls
  end

  def fetch_marchex_calls
    start_time = Time.zone.parse(params[:startDate]).beginning_of_day
    end_time   = Time.zone.parse(params[:endDate]).end_of_day
    calls = @client.marchex_call_records.where(start_time: start_time..end_time)
    search = params[:search][:value]
    if search.present?
      # Hack to make phone number search work with parens
      search.gsub!(/[()-]|\s+/, '') if search.match(/[()]/)
      calls = calls.where(%q(caller_name ILIKE :search OR
                             caller_number ILIKE :search OR
                             campaign ILIKE :search OR
                             group_name ILIKE :search OR
                             status ILIKE :search),
                          search: "%#{search}%")
    end
    calls.reorder("#{sort_column} #{sort_direction}").page(page).per_page(per_page)
  end

  def page
    params[:start].to_i/per_page + 1
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 20
  end

  def sort_column
    columns = %w[caller_name caller_number campaign group_name start_time duration status]
    columns[params[:order]['0']['column'].to_i]
  end

  def sort_direction
    params[:order]['0']['dir'] == 'desc' ? 'DESC' : 'ASC'
  end
end
