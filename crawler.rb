require 'net/http'
require 'mysql'

class WebCrawler
  attr_reader :connection

  def initialize()
    @connection = Mysql.new("localhost","root","","webcrawler")
  end

  private
  def check_data(site_data)
    row_count = @connection.query("SELECT `url` FROM `listings` WHERE `url`='#{site_data[:url]}'")
    if row_count.num_rows > 0
      return true
    else
      return false
    end
  end

  private
  def save_site_crawl(site_data)
    if !site_data[:description][1].nil?
      description_sanitized = site_data[:description][1].sub!("'","&#39;")
    else
      description_sanitized = "Description Not Availiable."
    end
    if !site_data[:keywords][1].nil?
      keywords_sanitized = site_data[:keywords][1].sub!("'","&#39;")
    else
      keywords_sanitized = "Keywords Not Availiable."
    end
    if !site_data[:title][1].nil?
      sanitized_title = site_data[:title][1].sub!("'","&#39;")
    else
      sanitized_title = site_data[:url]
    end

    if check_data(site_data)
      update_query = @connection.query("UPDATE `listings` SET `url`='#{site_data[:url]}', `title`='#{site_data[:title][1]}', `description`='#{site_data[:description][1]}', `keywords`='#{site_data[:keywords][1]}' WHERE `url`='#{site_data[:url]}'")
    else
      insert_query = @connection.query("INSERT INTO `listings` (`url`,`title`,`description`,`keywords`) VALUES ('#{site_data[:url]}','#{site_data[:title][1]}','#{description_sanitized}','#{keywords_sanitized}')")
    end
  end

  private
  def get_url_information(url)
    response = Net::HTTP.get_response(URI(url))
    case response
    when Net::HTTPSuccess then url = url
    when Net::HTTPRedirection then url = response['location']
    when Net::HTTPNotFound then return
    else puts "Other response code: #{response.code}"
    end
    page_source = Net::HTTP.get(URI.parse(url))
    title = page_source.match(/<title>(.*)<\/title>/i).to_a
    description = page_source.match(/<meta\s+(?:[^>]*?\s+)?name="description" content="([^"]*)"/i).to_a
    keywords = page_source.match(/<meta\s+(?:[^>]*?\s+)?name="keywords" content="([^"]*)"/i).to_a
    data_found = {url: url, title: title, description: description, keywords: keywords}
    puts "#{data_found[:url]}\n#{data_found[:title][1]}\n#{data_found[:description][1]}\n==============================\n"
    save_site_crawl(data_found)
  end

  private
  def fetch_database_urls
    active_urls = []
    fetch_urls = @connection.query("SELECT `url` FROM `listings`")
    while url = fetch_urls.fetch_row do
      active_urls.push(url)
    end
    return active_urls
  end

  private
  def exception()

  end

  public
  def crawl
    database_urls = fetch_database_urls()
    database_urls.each do |url_to_crawl|
      puts "Fetching Source For: #{url_to_crawl[0]}"
      begin
        page_source = Net::HTTP.get(URI.parse(url_to_crawl[0]))
        urls_found = page_source.scan(/<a\s+(?:[^>]*?\s+)?href="([^"]*)"/i).to_a
        urls_found.each do |url|
          case url[0][0..4]
          when "https" then get_url_information(url[0])
          when "http:" then get_url_information(url[0])
          else
            if url_to_crawl[url_to_crawl.length - 1] == "/"
              get_url_information(url_to_crawl[0] + url[0])
            else
              if url[0][0..1] == "/"
                get_url_information(url_to_crawl[0] + url[0])
              else
                get_url_information(url_to_crawl[0] + "/" + url[0])
              end
            end
          end
          sleep(0.5)
        end
      rescue StandardError
        puts "Could not contact: #{url_to_crawl[0]}"
      end
    end
    crawl()
  end
end

start = WebCrawler.new()
start.crawl
