#!/usr/bin/env ruby

#################################
# INCLUDING REQUIREMENTS        #
#################################

require 'rubygems'
require 'watir-webdriver'
require 'io/console'
require 'open-uri'
require 'tmpdir'
require 'rmagick'
require 'base64'
require 'net/http'
require 'rtesseract'
require 'CSV'
require 'nokogiri'
require 'timeout'
include Magick

#################################
#DEFINING METHODS AND VARIABLES	#
#################################



# DEFINING BIG VARIABLES
@url = 'faucet.bitcoinzebra.com'
$proxyList = []
$addressList = []
$b
#$doc = Nokogiri::HTML(open("http://www.socks-proxy.net/"))
$updateTime = Time.now

def superLoopedyLooper
  #updateProxies
  
  CSV.foreach('bitcoinaddresses.csv') do |line|
    $addressList << line[1]
  end
  
  CSV.foreach('proxyList.csv') do |line|
    $proxyList << line[0]
  end

   
  while true do
     
    for iter in 0..$proxyList.length
      puts iter
      proxyAddr = $proxyList[iter]
      btcAddress = $addressList[iter]
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile['network.proxy.socks_version'] = 4
      proxy = Selenium::WebDriver::Proxy.new(:socks => proxyAddr)
      profile.proxy = proxy

      # You have to do a little more to use the specific profile
      driver = Selenium::WebDriver.for :firefox, :profile => profile
      $b = Watir::Browser.new(driver)

      $b.goto (@url + "/preferences")
      countr = 0
      ready = false
      while(!ready and countr<10)
        ready = $b.title.chomp == 'Bitcoin Zebra - Preferences'
        puts ready 
        countr += 1
        puts countr
        sleep(1)
      end
      if !ready
        $b.close
        next
      end
=begin
      begin
        Timeout::timeout(10){ 
          while true
            onPage = $b.title.chomp == 'Bitcoin Zebra - Preferences'
            puts onPage
            if(onPage)
              break
            end
            sleep 1 
          end
        }
      rescue Timeout::Error => msg 
        puts $b.title
        puts $b.title.chomp == 'Bitcoin Zebra - Preferences'
        puts "Recovered from Timeout"
        $b.close
        next
      end
=end  
      sleep 1 until $b.select_list(:id => "BodyPlaceholder_CaptchaTypeDropdown").exists? 
      $b.select_list(:id => "BodyPlaceholder_CaptchaTypeDropdown").select "Recaptcha"
      $b.input(:id => 'BodyPlaceholder_UpdateButton').click

#      $b.cookies.add("user",cookie,{path: '/',domain: 'faucet.bitcoinzebra.com'})
      sleep 5
      $b.goto @url
#     cookie = "BitcoinAddress="+btcAddress+"&CaptchaType=0"
#      puts cookie
#     $b.cookies.add('user',cookie,:secure => false, :path => "/", :domain => 'faucet.bitcoinzebra.com')
      #$b.cookies.add("user",cookie,:path => '/',:domain => 'faucet.bitcoinzebra.com')
#     $b.refresh 
=begin
      begin
        Timeout::timeout(10) do
          sleep 1 until ($b.title == 'Bitcoin Zebra - Free Bitcoin Faucet')
        end
      rescue
        puts "RECOVERED"
        $b.close
        next
      end
=end
      countr = 0
      ready = false
      while(!ready and countr<10)
        ready = $b.title.chomp == 'Bitcoin Zebra - Free Bitcoin Faucet'
        puts ready 
        countr += 1
        puts countr
        sleep(1)
      end
      if !ready
        $b.close
        next
      end

    # COMPLETE THE ADDRESS FILLUP
      #sleep 1 until $b.text_field(:id => 'BodyPlaceholder_BitcoinAddressTextbox').exists?  
      $b.text_field(:id => 'BodyPlaceholder_BitcoinAddressTextbox').set(btcAddress)  
      sleep 1 until $b.input(:id => 'feedButton').exists? 
      $b.input(:id => 'feedButton').click
    # DEAL WITH THE CAPTCHAs
      sleep 1 until $b.image(:id => "recaptcha_challenge_image").exists? 
      puts " We're ready for the Captcha "
      left = $b.execute_script("return $('#recaptcha_challenge_image').offset().left").to_i
      top = $b.execute_script("return $('#recaptcha_challenge_image').offset().top").to_i
      height = $b.execute_script("return $('#recaptcha_challenge_image').innerHeight()").to_i
      width = $b.execute_script("return $('#recaptcha_challenge_image').innerWidth()").to_i

  
      screenshot = Image.read_inline($b.screenshot.base64).first
      captcha_image = screenshot.crop(left, top, width, height).write("ss_crop.png")
=begin  
      if checkForText height,width,captcha_image
        # INSERT TESSERACT SOLVER HERE
        captchaSolution = solveUsingOCR screenshot
        if(captchaSolution.empty? or not (captchaSolution.downcase.include? "enter" or captchaSolution.downcase.include? "answer") )
          captchaSolution = solveUsingService captcha_image
        elsif captchaSolution.downcase.include? "="
          captchaSolution.split("=")[2]
        elsif captchaSolution.downcase.include? "answer" 
          captchaSolution.downcase.split("answer").[2].delete(":","=").chomp
        end
      else

        captchaSolution = solveUsingService captcha_image
  
    
      end
=end
      captchaSolution = solveUsingService captcha_image
      sleep 1 until $b.text_field(:id => 'recaptcha_response_field').exists?
  
      $b.text_field(:id => 'recaptcha_response_field').set(captchaSolution)
      submit
      
      
    end
 
    if ($updateTime+(60*60) <=> Time.now) < 0
      sleep 10 until (($updateTime+(60*60) <=> Time.now) < 0)
    end
    $updateTime = Time.now
    
  end

   
end
=begin
def updateProxies
  $doc = Nokogiri::HTML(open("http://www.socks-proxy.net/"))
  newProxies = []
  for x in 0..200
    if x % 8 == 0
      newProxies << $doc.xpath("//td")[x].text + ":" + $doc.xpath("//td")[x+1].text
    else
      next
    end
  end
  newProxies.delete_if {|proxy| $usedProxies.include? proxy }
  $proxyList.clear
  $proxyList.concat newProxies
end
=end
#SETTING UP ENVIRONMENT


=begin
def checkForText (width, height, image)

  for x in 1..width
    for y in (height-25)..height
      color = image.pixel_color(x,y)
      red = color.red/257
      green = color.green/257
      blue = color.blue/257 
      max = [red,green,blue].max
      min = [red,green,blue].min
      if(max-min > 10)
        #puts red
        #puts green
        #puts blue
        #puts (x.to_s + " : " + y.to_s)
        #puts "false"
        return false
      end
    end
  end
  return true
end

def solveUsingOCR (image)
  image.crop(left,top+height-25,width,25).contrast(1).sharpen(1).level(0.1,0.4,).write("ss_double_crop.png")
  #x..write "meepo.png"
  rimg = RTesseract.new("ss_double_crop.png")
  puts rimg
  return rimg.to_s
end
=end
def solveUsingService (image)
  uri = URI('http://2captcha.com/in.php')

  captcha_base64 = Base64.encode64(image.to_blob)

  req = Net::HTTP::Post.new(uri)
  req.set_form_data('method' => 'base64', 'key' => @apiKey, 'body' => captcha_base64)

  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  captchaID = ''

  case res
  when Net::HTTPSuccess, Net::HTTPRedirection
    captchaID = res.body.partition('|')[2]
  else
    res.value
    # INSERT ERROR CODE HERE
  end

  resURI = URI('http://2captcha.com/res.php')
  params = { :key => @apiKey, :action => 'get', :id => captchaID}
  resURI.query = URI.encode_www_form(params)

  solved = false

  until solved do
    res = Net::HTTP.get_response(resURI)
    if res.is_a?(Net::HTTPSuccess) and (res.body != 'CAPCHA_NOT_READY')
      puts res.body
      solved = true
    else
      sleep 2
    end
    
  end
  return res.body.partition('|')[2]
end

def submit
  sleep 1 until $b.input(:class => 'submit-button').exists?
  $b.input(:class => 'submit-button').click
  sleep 2
  $b.close
end


#################################
# END OF METHOD DECLARATION			#
#################################






#################################
# RUNNING OF ACTUAL SCRIPT  		#
#################################


superLoopedyLooper
#submit
#################################
# END OF ACTUAL SCRIPT			#
#################################
