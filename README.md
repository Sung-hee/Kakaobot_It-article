## TechNeedle에서 포스팅 된 글 읽어오는 플러스친구

### 실습환경 c9

#### 우선 진행하기전에 Ruby_lion에서 카카오톡 자동응답API를 참고하시면 좋겠습니다 ! 

>1. 우선 컨트롤러부터 만들기
>
>   $ rails g controller kakao keyboard message
>
>2.  routes.rb 수정하기
>
>```ruby
>get '/keyboard' => 'kakao#keyboard'
>
>get '/message' => 'kakao#message'
># 지금은 get '/message'로 했지만 플러스친구에 배포할 땐 post로 고쳐주셔야 합니다 !
># 왜그러냐면 지금은 편하게 local에서 에러들을 고치기 위해서 get을 사용했기 때문입니다.
># get '/message' => 'kakao#message' -> post '/message' => 'kakao#message' 
>```
>
>3. kakao_controller.rb 수정하기 
>
>```ruby
># 후에는 keyboard type 을 text로 바꾸어 원하는 분야의 기사들을 가져와 읽어줄거지만 
># 지금은 buttons으로 하나의 기사만 가져오도록 해보겠습니다.
>def keyboard  
>  home_keyboard = {
>    :type => "buttons",
>    :buttons => ["챗봇"]
>  }
>  render json: home_keyboard
>end
>```
>
>4. helpers을 이용해서 모듈 관리하기
>
>```ruby
># 여기에선 모듈을 관리하여 컨트롤러에서 최소한의 코드만 작성하겠습니다. 
># 컨트롤러의 가독성을 위해서 helpers를 사용합니다 !
>module Parser
>    class Itnews
>        def techneedle
>          # 한글은 url에서 깨지기 때문에 url 한글로 변환함.
>          encode = URI.encode("챗봇")
>          # 변환한 url을 이용하여 검색 요청
>          url = "http://techneedle.com/?s=#{encode}" 
>          news_html = HTTParty.get(url)
>          doc = Nokogiri::HTML(news_html)
>          
>          # news 해쉬를 만들고 key값과 value 값을 이용하여 타이틀과 이미지를 저장
>          news = Hash.new
>           
>          doc.css("div.masonry-wrapper article").each do |article|
>             news[article.css("header h1.entry-title a").text] = {
>                 :title => article.css("div header h1.entry-header a"),
>                 :img => article.css("figure.post-thumbnail").to_s
>             }
>          end
>        
>        # 챗봇 답변을 위해 text 에는 타이틀과 이미지를 반환합니다.
>        return_text = news[:title]
>        img_url = news[:img]
>        
>        return return_text, img_url
>        end
>    end
>end
># 지금 이 코드는 완성된게 아니라 따라하셔도 text와 img 값이 null로 뽑힐 겁니다 !
># 이건 차차 고치도록 하겠습니다 ! 
># 수정되면 수정 부분을 올릴예정 !	
>```
>
>5. Httpart와 nokogiri 를 사용하기 위해 Gem 을 추가합시다 !
>
>```ruby
>gem 'httparty'
>gem 'nokogiri'
>gem 'uri-js-rails', :group => :assets
>
>$ bundle install & bundle
>```
>
>6. kakao_controller.rb에서 message 수정하기
>
>```ruby
>def message
>    # 사용자가 보낸 내용은 content에 담자.
>    user_msg = params[:content]
>    return_text = "임시텍스트"
>    image = false
>    
>    if user_msg = "it핫이슈"
>      image = true
>      
>      techneedle_news = Parser::Itnews.new
>      news_info = techneedle_news.techneedle
>      
>      return_text = news_info[0]
>      img_url = news_info[1]
>    end
>    
>    home_keyboard = {
>      :type => "buttons",
>      :buttons => ["IT기사"]
>    }
>    return_message_with_img = {
>      :message => {
>        :text => return_text,
>        :photo => {
>          :url => img_url,
>          :width => 640,
>          :height => 480
>        }
>      },
>      :keyboard => home_keyboard
>    }
>    return_message = {
>      :message => {
>        :text => return_text
>      },
>      :keyboard => home_keyboard
>    }
>
>    if image
>      render json: return_message_with_img
>    else
>      render json: return_message
>    end
>end
>```
>
>
>
>

