module Parser
  class Itnews
    def techneedle(user_msg)
      # puts user_msg
      encode = URI.encode("#{user_msg}")
      # encode = URI.encode("비트코인")
      # puts encode
      url = "http://techneedle.com/?s=#{encode}"
      news_html = HTTParty.get(url)
      doc = Nokogiri::HTML(news_html)

      news = Hash.new
      titles = Array.new

      doc.css("div.masonry-wrapper > article").each do |article|
        if article.css('figure > a > img').empty?
          news[article.css("header > h1 > a").text] = {
          :title => article.css("header > h1 > a").text,
          :img => "",
          :url => article.css("header > h1 > a")[0]['href']
        }
        else
          news[article.css("header > h1 > a").text] = {
          :title => article.css("header > h1 > a").text,
          :img => article.css('figure > a > img').attr('src').to_s,
          :url => article.css("header > h1 > a")[0]['href']
        }
        end
      end
      # puts news.inspect

      doc.css("div.masonry-wrapper > article > header > h1 > a").each do |title|
        titles << title.text
      end

      news_info = titles.sample

      return_text = news[news_info][:title]
      img_url = news[news_info][:img]
      link_url = news[news_info][:url]

      return [return_text, img_url, link_url]
    end
  end
end
