namespace :mitcpw do
  desc "Download the events from mitcpw.org. "
  task download: :environment do
    require 'net/http'
    require 'json'
    require 'nokogiri'

    # Initializations
    events = []
    now = Time.now.to_i

    # Fetch the pages from the AJAX entrypoint to speed up
    uri = URI('http://www.mitcpw.org/views/ajax')

    # Create a persistent HTTP connection
    http = Net::HTTP.new(uri.host, uri.port)

    def fetch_slots(page, http)
      # Request the page
      puts "Requesting page #{page}"
      request = Net::HTTP::Post.new('/views/ajax')
      request.set_form_data({"view_name" => "events", "view_display_id" => "page_1", "page" => page - 1})
      page = http.request(request).body

      # Parse the JSON response
      json = JSON.parse(page)
      insert = json.select { |c| c['command'] == 'insert' }[0]
      content = insert['data']

      # Break if there are no events
      return {} if content =~ /There are no events listed/

      # Parse the HTML
      doc = Nokogiri::HTML(content)
      root = doc.css('.view-content').first
      current_slot = nil
      slots = {}
      root.children.each do |node|
        if node.name == 'h3'
          current_slot = node.css('.date-display-single').first.text
        elsif node.name == 'div'
          path = node.css('.main-link-event').first['href']
          slots[current_slot] ||= []
          slots[current_slot] << path
        end
      end

      slots
    end

    event_paths = []

    total_pages = 0
    pages = {}
    while true
      try = fetch_slots(total_pages + 1, http)
      break if try.empty?
      total_pages += 1
      pages[total_pages] = try
      try.values.each { |v| event_paths += v }
    end

    1.upto(total_pages - 1) do |p|
      # Fix the gap between page p and page p + 1 due to display order randomization
      a = pages[p].values.last
      b = pages[p + 1].values.first

      ka = pages[p].keys.last
      kb = pages[p + 1].keys.first

      next unless ka == kb

      comb = (a + b).uniq
      should_be_size = a.size + b.size

      while comb.size != should_be_size
        na = fetch_slots(p, http).values.last
        comb = (comb + na).uniq
        break if comb.size == should_be_size
        nb = fetch_slots(p + 1, http).values.first
        comb = (comb + nb).uniq
      end

      event_paths += comb
    end

    event_paths.uniq!

    FileUtils.mkdir_p('/tmp/cpw_events')
    File.write("/tmp/cpw_events/#{now}.list", event_paths.join("\n"))
    File.write("/tmp/cpw_events/latest.list", event_paths.join("\n"))

    # Fetch individual events
    event_paths.each_with_index do |e, i|
      event_doc = Nokogiri::HTML(http.get(e).body)

      title = event_doc.at_css('.node-title').text
      date_start = event_doc.at_css('.date-display-start')['content']
      date_end = event_doc.at_css('.date-display-end')['content']
      location = event_doc.at_css('.field-name-field-event-location .field-item').text rescue ''
      type = event_doc.css('.field-name-field-event-type .field-item').map { |x| x.text }
      summary = event_doc.at_css('.field-name-body .field-items').text rescue ''

      puts "  (%03d/%03d) %s" % [i + 1, event_paths.size, title]

      event = {
        title: title,
        from: date_start,
        to: date_end,
        location: location,
        type: type,
        summary: summary,
        path: e
      }

      events << event
    end

    events.uniq! { |e| e[:path] }

    File.write("/tmp/cpw_events/#{now}.yml", events.to_yaml)
    File.write("/tmp/cpw_events/latest.yml", events.to_yaml)
  end

  desc "Importing the events downloaded by mitcpw:download task into the database. "
  task import: :environment do
    require 'yaml'

    puts 'Loading YAML'

    datetime_now = DateTime.now
    puts "Updating at #{datetime_now}"

    events = YAML.load_file("/tmp/cpw_events/latest.yml")

    puts 'Checking for changed events'

    changed_cpw_ids = []
    added_cpw_ids = []
    removed_event_names = []

    events.each do |e|
      cpw_id = /-([0-9]*)$/.match(e[:path])[1].to_i
      original = Event.find_by(cpw_id: cpw_id)

      if original
        if original.title != e[:title] \
        || original.from != e[:from] \
        || original.to != e[:to] \
        || original.location != e[:location] \
        || original.summary != e[:summary]
          changed_cpw_ids << cpw_id
        end
      else
        added_cpw_ids << cpw_id
      end
    end

    Event.all.each do |e|
      new_event = events.select { |x| /-([0-9]*)$/.match(x[:path])[1].to_i == e.cpw_id }.first

      if !new_event
        removed_event_names << e.title
      end
    end

    puts 'Wiping out old data'
    Type.destroy_all
    Event.destroy_all

    puts 'Creating the following types'

    types = []
    events.each { |x| types += x[:type] }

    types.sort!.uniq!

    type_hash = {}

    types.each do |x|
      puts '  ' + x

      type = Type.new
      type.title = x
      type.save

      type_hash[x] = type
    end

    puts 'Importing the events'

    events.each do |e|
      print '.'

      cpw_id = /-([0-9]*)$/.match(e[:path])[1].to_i

      event = Event.new

      event.title = e[:title]
      event.from = e[:from]
      event.to = e[:to]
      event.location = e[:location]
      event.summary = e[:summary]
      event.cpw_id = cpw_id

      e[:type].each { |t| event.types << type_hash[t] }

      event.save!
    end

    puts
    puts 'Following changes have occurred'

    changed_cpw_ids.each do |i|
      event_name = Event.find_by(cpw_id: i).title
      message = "Event \"#{event_name}\" has changed."
      puts "  " + message
      Changelog.create(message: message, cpw_id: i, changetime: datetime_now)
    end

    removed_event_names.each do |i|
      message = "Event \"#{i}\" has been removed."
      puts "  " + message
      Changelog.create(message: message, cpw_id: nil, changetime: datetime_now)
    end

    added_cpw_ids.each do |i|
      event_name = Event.find_by(cpw_id: i).title
      message = "Event \"#{event_name}\" has been added."
      puts "  " + message
      Changelog.create(message: message, cpw_id: i, changetime: datetime_now)
    end

    total_changes = changed_cpw_ids.size + removed_event_names.size + added_cpw_ids.size

    message = "Events synced at #{datetime_now.to_formatted_s(:long_ordinal)}, #{total_changes} changes detected. "
    puts message
    Changelog.create(message: message, cpw_id: nil, changetime: datetime_now)

  end

end
