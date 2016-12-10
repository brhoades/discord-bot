require 'mechanize'
require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'
require 'pathname'

Capybara.default_max_wait_time = 10
Capybara.run_server = false
Capybara.current_driver = :poltergeist
# Capybara.app_host = 'http://soc'
uri = URI('https://socialclub.rockstargames.com/profile/signin')

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {js_errors: false})
end

def write_cookies cookies
  res = Marshal::dump cookies
  File.write("cookies", res)

  puts "Wrote #{cookies.size} cookie(s)"
end

def read_cookies driver
  return if not File.exists? "cookies"
  res = Marshal::load(File.read("cookies"))

  res.each do |k, v|
    driver.set_cookie(k, v)
  end
  puts "Loaded #{res.size} cookie(s)"
end

module MyCapybaraTest
  class Test
    include Capybara::DSL
    def login
      begin
        uri = URI('https://socialclub.rockstargames.com/profile/signin')
        visit uri
        return if logged_in
        captcha_check
        fill_in "login-field", with: ENV["GTA_USER"]
        fill_in "password-field", with: ENV["GTA_PASS"]
        check "rememberme-field"
        click_on "Sign In"
        captcha_check
        find("#gamesPanel")
      rescue Capybara::ElementNotFound, Capybara::Ambiguous
        failed
        exit
      end
    end

    def get_basic_statistics last_time=false
      read_cookies page.driver
      page.driver.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36', permanent: true)
      login
      begin
        uri = URI("https://socialclub.rockstargames.com/games/gtav/career/overviewAjax?character=Freemode&nickname=foukemonster&slot=Freemode&gamerHandle=&gamerTag=&_=1419694640015")
        visit uri
        find("#bank-value")
        return page.body
      rescue Capybara::ElementNotFound, Capybara::Ambiguous
        failed
        return if last_time
        get_basic_statistics true
      end
      write_cookies page.driver.browser.cookies end

    def captcha_check
      begin
        original = Capybara.default_max_wait_time
        Capybara.default_max_wait_time = 3
        find("#recaptcha_privacy")
        puts "CAPTCHA"
        exit
      rescue Capybara::ElementNotFound
      end
      Capybara.default_max_wait_time = original
    end

    def failed
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
      return true
    end
  end
end


t = MyCapybaraTest::Test.new
statistics = t.get_basic_statistics

#Sorry, but you made too many requests. Please check back in a short while to see if the restriction has been lifted.
puts statistics
