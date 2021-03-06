module W3CMobileOk
  class Parser
    URL = 'http://validator.w3.org/mobile/check?&docAddr='

    def initialize(url)
      @url = "#{URL}#{url}"
    end

    def parse!
      agent = Mechanize.new

      # from http://mechanize.rubyforge.org/Mechanize.html#method-i-keep_alive-3D
      # to skip Error: too many connection resets (due to Net::ReadTimeout - Net::ReadTimeout) 
      agent.keep_alive = false

      page = agent.get @url

      # if the given URL doesn't exist any more
      raise NonExistentResourceError if page.link_with(text: /The resource under test could not be retrieved./)

      result = Result.new
      result.score = page.search('#score .hd strong').text
      result.page_size = page.search('#pagesize .hd strong').text
      result.network_usage = page.search('#network .hd strong').text

      page.search('#pagesize .details tr').each do |node|
        unless node.search('th').any?
          resource = Resource.new
          resource.size = node.children.search('td')[0].text.strip
          resource.type = node.children.search('td')[1].text.strip
          resource.uri = node.children.search('td')[2].text.strip

          result.resources << resource
        end
      end

      page.search('#details li.mod').each do |node|
        failure = Failure.new
        failure.severity = node.search('.severity img').first['alt']
        failure.category = node.search('.cat img').first['alt']
        failure.description = node.search('.desc').children.last.text.split("\n").map(&:strip).join(' ')

        failure.best_practice = BestPractice.new
        failure.best_practice.why = node.search('.why .explanation').children.last.text.split("\n").map(&:strip).join(' ') if node.search('.why .explanation').children.any?
        failure.best_practice.how = node.search('.how .explanation').children.last.text.split("\n").map(&:strip).join(' ') if node.search('.how .explanation').children.any?
        failure.best_practice.where = node.search('div[id$=where] .explanation').children.map(&:text).join.split("\n").map(&:strip).join(' ') if node.search('div[id$=where] .explanation').children.any?

        result.failures << failure
      end

      result
    end
  end
end
