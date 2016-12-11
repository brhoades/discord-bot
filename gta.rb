require 'mechanize'
require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'
require 'pathname'
require 'nokogiri'

Capybara.default_max_wait_time = 3
Capybara.run_server = false
Capybara.current_driver = :poltergeist
Capybara.ignore_hidden_elements = false
# Capybara.app_host = 'http://soc'
uri = URI('https://socialclub.rockstargames.com/profile/signin')

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {js_errors: false, cookies: true, window_size: [1920, 1080]})
end

def write_cookies cookies
  serial = []
  cookies.each do |k, v|
    serial << {
      key: k,
      value: v.value,
      options: {
        domain: v.domain,
        expires: v.expires,
        path: v.path,
        samesite: v.samesite,
        httponly: v.httponly?
      }
    }
  end
    
  res = Marshal::dump serial
  File.write("cookies", res)

  puts "Wrote #{cookies.size} cookie(s)"
end

def read_cookies driver
  return if not File.exists? "cookies"
  res = Marshal::load(File.read("cookies"))

  res.each do |cookie| 
    driver.set_cookie(cookie[:key], cookie[:value], cookie[:options])
  end
end

def pack_common(titles, values)
  res = {}
  titles.zip(values).each do |title, value|
    res[title] = value
  end

  res
end

def parse_page html
  page = Nokogiri::HTML(html)
  results = {}

  results[:play_time] = page.css('.rankXP > .rankBar > h4')[0].text.gsub(/Play Time: /, "")
  results[:rank] = page.css('.rankHex > h3:nth-child(1)').text

  cash = page.css('.rankStats > p > span').map { |e| e.text }
  results[:cash] = cash[1]
  results[:bank] = cash[3]

  earned_titles = page.css('.cash-val > h5').map {|t| t.text}
  earned_values = page.css('.cash-val > p').map {|t| t.text}

  results[:earned] = pack_common(earned_titles, earned_values)

  crimes_headers = page.css('.gridRow > .span4col > li > h5').map {|c| c.text}
  crimes_values = page.css('.gridRow > .span4col > li > p').map {|c| c.text}

  results[:crimes] = pack_common(crimes_headers, crimes_values)

  results
end

module MyCapybaraTest
  class Test
    include Capybara::DSL
    def login
      begin
        # uri = URI('https://socialclub.rockstargames.com/profile/signin')
        # visit uri
        return if logged_in
        puts "LOGGING IN"
        captcha_check
        # fill_in "login-field", with: ENV["GTA_USER"]
        # fill_in "password-field", with: ENV["GTA_PASS"]
        # check "rememberme-field"
        # click_on "Sign In"
        click_on "headerLoginButton"
        fill_in "headLoginString", with: ENV["GTA_USER"]
        fill_in "headLoginPassword", with: ENV["GTA_PASS"]
        check "rememberme"
        begin
          find("button.btn:nth-child(3)").click
        rescue Capybara::Poltergeist::MouseEventFailed
          find('#headLoginPassword').native.send_keys(:enter)
        end
        captcha_check 3
        puts "LOGGED IN"
      rescue Capybara::ElementNotFound, Capybara::Ambiguous, Capybara::Poltergeist::MouseEventFailed
        failed
        exit
      end
    end

    def get_basic_statistics last_time=false
      read_cookies(page.driver) if not last_time
      page.driver.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36', permanent: true)
      begin
        uri = URI("https://socialclub.rockstargames.com/games/gtav/career/overviewAjax?character=Freemode&nickname=foukemonster&slot=Freemode&gamerHandle=&gamerTag=&_=1419694640015")
        visit uri
        find("#bank-value")
        return page.body
      rescue Capybara::ElementNotFound, Capybara::Ambiguous
        failed
        return if last_time
        login
        get_basic_statistics true
      end
    end

    def captcha_check(wait=0)
      begin
        puts "CAPTCHA CHECK"
        original = Capybara.default_max_wait_time
        Capybara.default_max_wait_time = wait
        find("#recaptcha_privacy")
        puts "CAPTCHA"
        write_cookies page.driver.browser.cookies
        exit
      rescue Capybara::ElementNotFound
      end
      Capybara.default_max_wait_time = original
    end

    def failed
        puts "FAILURE"
        puts $!
        name = page.save_screenshot
        `scp #{name} aaron@i.brod.es:/var/www/images/`
        basename = Pathname.new(name).basename
        puts "http://i.brod.es/#{basename}"
        `rm #{name}`
        write_cookies page.driver.browser.cookies
    end
    def logged_in
      begin
        find("#gamesPanel")
      rescue Capybara::ElementNotFound, Capybara::Ambiguous
        return false
      end

      puts "LOGGED IN"
      return true
    end
  end
end


t = MyCapybaraTest::Test.new
statistics = t.get_basic_statistics
results = parse_page statistics

puts results

#Sorry, but you made too many requests. Please check back in a short while to see if the restriction has been lifted.
