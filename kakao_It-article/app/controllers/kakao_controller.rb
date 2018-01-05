class KakaoController < ApplicationController
  require 'httparty'
  require 'nokogiri'

  def keyboard
    home_keyboard = {
      :type => "text"
    }
    render json: home_keyboard
  end

  def message
    # 사용자가 보낸 내용은 content에 담자.
    user_msg = params[:content]
    return_text = "임시텍스트"
    image = false

    if user_msg == params[:content]
      image = true

      techneedle_news = Parser::Itnews.new
      news_info = techneedle_news.techneedle(user_msg)

      return_text = news_info[0]
      img_url = news_info[1]
      link_url = news_info[2]
    end

    # home_keyboard = {
    #   :type => "buttons",
    #   :buttons => ["챗봇"]
    # }

    home_keyboard = {
      :type => "text"
    }

    return_message_with_img = {
      :message => {
        :text => return_text,
        :photo => {
          :url => img_url,
          :width => 640,
          :height => 480
        },
        :message_button => {
          :label => "기사 더보기",
          :url => link_url
        }
      },
      :keyboard => home_keyboard
    }
    return_message = {
      :message => {
        :text => return_text
      },
      :keyboard => home_keyboard
    }

    if image
      render json: return_message_with_img
    else
      render json: return_message
    end
  end
end
