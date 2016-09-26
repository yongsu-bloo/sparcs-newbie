require 'opencv'
include OpenCV
require 'open-uri'
require 'net/http'
require 'webrick/httputils'

class HomeController < ApplicationController
  def index
  end
  
  def photo
    option = params[:option] # 선택 부위(정면, 눈, 코 등)
    search = params[:search] # 검색어
    search_option = params[:search_option] # 프로필 사진 여부(on/off)
    
    data = '/usr/share/opencv/haarcascades/haarcascade_%s.xml' % option
    detector = CvHaarClassifierCascade::load(data)
    
    # input image 저장
    if not params[:photo_file].nil? # 파일이 입력된 경우
      img_path = params[:photo_file].path
      input_image_path = img_path
    elsif not params[:url].empty? # url이 입력된 경우
      # URL로 이미지 저장
      # input_image_path = img_path.sub!( /[^\s]+(\.)/, "input.")
      open("/home/ubuntu/workspace/app/assets/images/input.png", 'wb') do |file|
        file << open(params[:url]).read()
      end
      input_image_path = "/home/ubuntu/workspace/app/assets/images/input.png"
    else # search
      if search_option == "on" # 프로필 사진
        url = "https://search.naver.com/search.naver?where=nexearch&query=#{search}&sm=top_hty&fbm=1&ie=utf8"
        url.force_encoding('binary')
        url=WEBrick::HTTPUtils.escape(url)
        doc = Nokogiri::HTML(open(url, 'User-Agent' => 'ruby'))#.read
        img_urls = doc.css(".profile_wrap//img").map{ |i| i['src'] }
        searched_img_url = img_urls[0]
        img_path = searched_img_url
        # URL로 이미지 저장
        open("/home/ubuntu/workspace/app/assets/images/input.png", 'wb') do |file|
          file << open(img_path).read()
        end
        input_image_path = "/home/ubuntu/workspace/app/assets/images/input.png"
      else # 뉴스 사진
        uri = URI(URI.encode("https://openapi.naver.com/v1/search/image.xml?query=#{search}&sort=sim"))
        req = Net::HTTP::Get.new(uri)
        req['X-Naver-Client-Id'] = "SnNTq9ukhEXV8VhhKOoy"
        req['X-Naver-Client-Secret'] = "oPVM5Zatal"
        res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') {|http|
          http.request(req)
        }
        xml_doc = Nokogiri::XML(res.body)
        links = xml_doc.xpath("//link")
        if not params[:choice_num].empty?
          choice_num = params[:choice_num].to_i
        else
          choice_num = 1
        end
        searched_img_url = links[choice_num].inner_text
        img_path = searched_img_url
        # URL로 이미지 저장
        open("/home/ubuntu/workspace/app/assets/images/input.png", 'wb') do |file|
          file << open(img_path).read()
        end
        input_image_path = "/home/ubuntu/workspace/app/assets/images/input.png"
      end
    end
    # input image 저장 끝
    
    # image processing and output save
    image = CvMat.load(input_image_path)
    detector.detect_objects(image).each do |region|
      width = region.bottom_right.x - region.top_left.x
      height = region.bottom_right.y - region.top_left.y
      
      first_image = MiniMagick::Image.open input_image_path
      # 그림 덮어씌우기
      case option
      when "frontalface_alt"
        second_image = MiniMagick::Image.open "cat_ear2.png"
        second_image.resize(width.to_s + "x" + height.to_s)
        result = first_image.composite(second_image) do |c|
          c.compose "Over" # OverCompositeOp
          c.geometry "+#{(region.top_left.x).to_s}+#{(region.top_left.y - height*0.5).to_s}"
          # c.geometry "+0+0" # copy second_image onto first_image from (0, 0)
        end
        # save
        result.write("/home/ubuntu/workspace/app/assets/images/input.png")
        input_image_path = "/home/ubuntu/workspace/app/assets/images/input.png"
      when "eye"
        second_image = MiniMagick::Image.open "heart.png"
        second_image.resize(width.to_s + "x" + height.to_s)
        result = first_image.composite(second_image) do |c|
          c.compose "Over" # OverCompositeOp
          c.geometry "+#{(region.top_left.x).to_s}+#{(region.top_left.y).to_s}"
        end
        # save
        result.write("/home/ubuntu/workspace/app/assets/images/input.png")
        input_image_path = "/home/ubuntu/workspace/app/assets/images/input.png"
      # when "eye_tree_eyeglasses"
      # when "mcs_mouth"
      # when "smile"
      # when "mcs_nose"
      # when "fullbody"
      # when "lowerbody"
      # when "upperbody"
      else
        color = CvColor::Blue
        image.rectangle! region.top_left, region.bottom_right, :color => color
        # save
        image.save_image("/home/ubuntu/workspace/app/assets/images/input.png")
        input_image_path = "/home/ubuntu/workspace/app/assets/images/input.png"
      end
      # 그림 덮어씌우기 끝
    end
    # image processing and output save 끝
    @img_path = input_image_path.sub!( /[^\s]+(\.)/, "input.")
    # send_file(input_image_path, disposition: 'inline')
  end
  
  def down
    send_file("/home/ubuntu/workspace/app/assets/images/input.png")
  end
end
