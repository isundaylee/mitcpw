namespace :mitcpw do
  desc "Download the events from mitcpw.org. "
  task download: :environment do

    def download_page(page)
      require 'nokogiri'
      require 'yaml'

      def retrieve(url)
        require 'fileutils'
        require 'digest/md5'
        require 'open-uri'

        FileUtils.mkdir_p("/tmp/caches")

        digest = Digest::MD5.hexdigest(url)
        path = "/tmp/caches/#{digest}"

        return File.read(path) if File.exists?(path)

        File.write(path, open(url).read)
        File.read(path)
      end

      puts "Downloading page #{page + 1}"
      url = "http://www.mitcpw.org/schedule/events/2014-04?page=%d" % page

      doc = Nokogiri::HTML(retrieve(url))

      events = []

      doc.css('.main-link-event').each do |e|
        event_url = "http://www.mitcpw.org" + e['href']
        event_doc = Nokogiri::HTML(retrieve(event_url))

        title = event_doc.at_css('.node-title').text
        date_start = event_doc.at_css('.date-display-start')['content']
        date_end = event_doc.at_css('.date-display-end')['content']
        location = event_doc.at_css('.field-name-field-event-location .field-item').text rescue ''
        type = event_doc.css('.field-name-field-event-type .field-item').map { |x| x.text }
        summary = event_doc.at_css('.field-name-body .field-items').text rescue ''

        puts '  ' + title

        event = {
          title: title,
          from: date_start,
          to: date_end,
          location: location,
          type: type,
          summary: summary,
          url: event_url
        }

        events << event
      end

      events
    end

    all_events = []

    current_page = 0
    while true
      events = download_page(current_page)
      break unless !events.empty?
      all_events += events
      current_page += 1
    end

    File.write('/tmp/cpw_events.yml', all_events.to_yaml)
  end

  desc "Importing the events downloaded by mitcpw:download task into the database. "
  task import: :environment do
    require 'yaml'

    puts 'Loading YAML'

    datetime_now = DateTime.now
    puts "Updating at #{datetime_now}"

    events = YAML.load_file("/tmp/cpw_events.yml")
    events.uniq! { |e| e[:url] }

    puts 'Checking for changed events'

    changed_cpw_ids = []
    added_cpw_ids = []
    removed_event_names = []

    events.each do |e|
      cpw_id = /-([0-9]*)$/.match(e[:url])[1].to_i
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
      new_event = events.select { |x| /-([0-9]*)$/.match(x[:url])[1].to_i == e.cpw_id }.first

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

      cpw_id = /-([0-9]*)$/.match(e[:url])[1].to_i

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

    changed_cpw_ids.each { |i| puts "  Event #{i} has changed. " }
    removed_event_names.each { |i| puts "  Event \"#{i}\" has been removed. " }
    added_cpw_ids.each { |i| puts "  Event #{i} has been added. " }

  end

end
