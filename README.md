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



### 전에 안되던 코드 수정 및 button 형식 봇 완성코드 !

>1. parser.rb 수정하기
>
>```ruby
>module Parser
>  class Itnews
>    def techneedle
>      .....
>      news = Hash.new
>      # 해쉬에서 value 값들을 담기 위한 배열 
>      titles = Array.new
>      images = Array.new
>      urls = Array.new
>          
>      doc.css("div.masonry-wrapper > article").each do |article|
>        news[article.css("header > h1 > a").text] = {
>        :title => article.css("header > h1 > a").text,
>        :img => article.css("figure > a > img").attribute('src').to_s,
>        :url => article.css("header > h1 > a")[0]['href']
>        }
>      end
>      # puts news.inspect
>      # 해쉬 반복을 통해서 배열에 value 값들을 담아주고
>      news.each do |key, value|
>        titles <<  news[key][:title]
>        images << news[key][:img]
>        urls << news[key][:url]
>      end
>      # 무작위로 하나를 뽑아 반환하자
>      return_text =  titles.sample
>      img_url =  images.sample
>      link_url = urls.sample
>      
>      return [return_text, img_url, link_url]
>    end
>  end
>end
>```
>
>#### 전의 코드에서 Null값이 나왔던 이유는 무엇일까 ?
>
>```ruby
># 변경 전
>doc.css("div.masonry-wrapper article").each do |article|
>  news[article.css("header h1.entry-title a").text] = {
>    :title => article.css("div header h1.entry-header a"),
>    :img => article.css("figure.post-thumbnail").to_s
>  }
>end
># 변경 후
>doc.css("div.masonry-wrapper > article").each do |article|
>  news[article.css("header > h1 > a").text] = {
>    :title => article.css("header > h1 > a").text,
>    :img => article.css("figure > a > img").attribute('src').to_s,
>    :url => article.css("header > h1 > a")[0]['href']
>  }
>end
>```
>
>위에 코드와 같이 우선 접근 방법 시 '>' 가 붙었으며 클래스 명으로 접근하지 않고 태그들로 접근했다 !
>
>아직까진 정확히 무슨 차이인지는 잘 모르겠다....ㅋ 무튼 해결함 !
>
>  
>
>2.  kakao_controller.rb 수정하기
>
>```ruby
>def message
>  ....
>  if user_msg = "it핫이슈"
>    image = true
>    techneedle_news = Parser::Itnews.new
>    news_info = techneedle_news.techneedle
>      
>    return_text = news_info[0]
>    img_url = news_info[1]
>    link_url = news_info[2]
>  end
>  
>  home_keyboard = {
>    :type => "buttons",
>    :buttons => ["챗봇"]
>  }
>  
>  return_message_with_img = {
>    :message => {
>      :text => return_text,
>      :photo => {
>      :url => img_url,
>      :width => 640,
>      :height => 480
>      },
>      :message_button => {
>        :label => "기사 더보기",
>        :url => link_url
>        }
>      },
>      :keyboard => home_keyboard
>    }
>  return_message = {
>    :message => {
>      :text => return_text
>    },
>    :keyboard => home_keyboard
>  }
>  if image
>    render json: return_message_with_img
>  else
>    render json: return_message
>  end
>end
>```
>
> 

### 세번째 수정 !

> 오류를 발견했다 !
>
> ```ruby
> return_text =  titles.sample
> img_url =  images.sample
> link_url = urls.sample
> ```
>
> 이 코드는 배열에 저장되어있는 값들 중 하나를 랜덤으로 뽑아서 각각 변수에 저장해주는 코드이다 !
>
> 결과적으로 text와 img_url, link_url 세개의 변수가 각각 똑같은 기사에서 값들을 가져와야 하는데 
>
> sample 이란 함수 덕분에 서로 다른 값들을 가져와 버린다. 
>
> 그래서 코드를 수정했다 !
>
> #### 수정된 코드
>
> ```ruby
> news = Hash.new
> titles = Array.new
>
> doc.css("div.masonry-wrapper > article").each do |article|
>   news[article.css("header > h1 > a").text] = {
>     :title => article.css("header > h1 > a").text,
>     :img => article.css("figure > a > img").attribute('src').to_s,
>     :url => article.css("header > h1 > a")[0]['href']  
>   }
> end
>
> # 타이틀만 뽑아 titles 배열에 값들을 저장하고
> doc.css("div.masonry-wrapper > article > header > h1 > a").each do |title|
>   titles << title.text
> end
> # 저장된 값들을 무작위로 하나 뽑는다.
> news_info = titles.sample
> # 그리고 무작위로 뽑은 값 하나를 news해쉬의 key에 넣어주고 
> # key를 이용해 저장된 value 값들을 뽑아서 반환해준다.
> return_text = news[news_info][:title]
> img_url = news[news_info][:img]
> link_url = news[news_info][:url]
>   
> return [return_text, img_url, link_url]
> ```
>
> 이러면 진짜 완성 !  이제부터는 button 타입을 text 타입으로 바꿔 카카오톡에서 텍스트가 들어오면 해당 텍스트로 기사들을 검사하여 보여주는 봇으로 바꾸겠음 !





## 완성본 ! 마지막 수정 !

>이걸 마지막으로 이 챗봇은 완성 !
>
>이제는 button 타입에서 text타입으로 변경하여 사용자가 text를 입력하면 해당 기사를 가져올 수 있도록 변경하겠습니다. 
>
>1. controller.rb 수정하기
>
>```ruby
>def keyboard  
>  home_keyboard = {
>    :type => "text"
>  }
>  render json: home_keyboard
>end
>
>def message
>  .....
>  home_keyboard = {
>    :type => "text"
>  }
>  return_message_with_img = {
>    :message => {
>      :text => return_text,
>      :photo => {
>        :url => img_url,
>        :width => 640,
>        :height => 480
>       },
>      :message_button => {
>        :label => "기사 더보기",
>        :url => link_url
>      }
>    },
>   :keyboard => home_keyboard
>  }
>  ....
>end
>```
>
>2. parser.rb 수정하기
>
>```ruby
># 함수에 파라미터를 지정하여 컨트롤러에서의 user_msg를 사용하여 사용자가 입력한 텍스트를 활용하도록 합시다 !
>def techneedle(user_msg)
>  encode = URI.encode("#{user_msg}")
>  doc.css("div.masonry-wrapper > article").each do |article|
>    # 여기는 기사에서 이미지가 없을 때 
>    if article.css('figure > a > img').empty
>      news[article.css("header > h1 > a").text] = {
>        :title => article.css("header > h1 > a").text,
>        :img => "",
>        :url => article.css("header > h1 > a")[0]['href']
>      } 
>    # 여기는 기사에 이미지가 있을 때
>    else
>      news[article.css("header > h1 > a").text] = {
>        :title => article.css("header > h1 > a").text,
>        :img => article.css('figure > a > img').attr('src').to_s,
>        :url => article.css("header > h1 > a")[0]['href']
>      }  
>    end
>end
>```
>
>3. 끝 ! 

