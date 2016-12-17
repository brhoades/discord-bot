require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'
require 'pathname'
require 'nokogiri'
require_relative '../../bot-feature.rb'

class GTATrackerFeature < BotFeature
  def load(bot)
    config = bot.get_config_for_module(__FILE__)
    @config = {
      "tracked_user": "",
      "gta_user": "",
      "gta_pass": ""
    }

    bot.map_config(config, @config)

    @last_tracked = {
      in_game: nil,
      timestamp: nil,
      is_online: false
    }

    Capybara.default_max_wait_time = 3
    Capybara.run_server = false
    Capybara.current_driver = :poltergeist
    Capybara.ignore_hidden_elements = false

    Capybara.register_driver :poltergeist do |app|
      Capybara::Poltergeist::Driver.new(app, {
        js_errors: false,
        cookies: true,
        window_size: [1920, 1080]
      })
    end
  end

  def register_handlers(bot, scheduler)
    bot.message(contains: /^[!\/]gta/) do |event|
      if @config[:tracked_user] == "" or @config[:gta_pass] == "" or @config[:gta_user] == ""
        event.respond "Not properly configured."
      else
        event.respond pretty_message
      end
    end

    scheduler.every '100000000h' do
      next
      results = scrape
      play_time = results[:Play_time]
      if @last_tracked[:in_game] != nil and @last_tracked[:in_game] != play_time
        if !@last_tracked[:is_online]
          @last_tracked[:is_online] = true
          channels = bot.find_channel("general", "testing server")
          channels.each do |channel|
            bot.send_message "#{@config["tracked_user"]} IS ONLINE", channels
          end
        end
      else
        @last_tracked[:is_online] = false
      end

      @last_tracked[:in_game] = play_time
    end
  end

  def pretty_message
    message = []
    results = scrape
    
    results.each do |k, v|
      if !v.is_a? Hash
        message << "#{k}: #{v}"
      else
        message << "#{k}"
        v.each do |k, v|
          message << "  #{k}: #{v}"
        end
      end
    end
    
    message.join "\n"
  end

  private

  def pack_common(titles, values)
    res = {}
    titles.zip(values).each do |title, value|
      res[title] = value
    end

    res
  end

  def parse_page(html)
    page = Nokogiri::HTML(html)
    results = {}

    results[:Play_time] = page.css('.rankXP > .rankBar > h4')[0].text.gsub(/Play Time: /, "")
    results[:Rank] = page.css('.rankHex > h3:nth-child(1)').text

    cash = page.css('.rankStats > p > span').map { |e| e.text }
    results[:Cash] = cash[1]
    results[:Bank] = cash[3]

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

      def write_cookies(cookies)
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

      def read_cookies(driver)
        return if not File.exists? "cookies"
        res = Marshal::load(File.read("cookies"))

        res.each do |cookie| 
          driver.set_cookie(cookie[:key], cookie[:value], cookie[:options])
        end
      end

      def login(config)
        begin
          # uri = URI('https://socialclub.rockstargames.com/profile/signin')
          # visit uri
          return if logged_in
          captcha_check
          # fill_in "login-field", with: ENV["GTA_USER"]
          # fill_in "password-field", with: ENV["GTA_PASS"]
          # check "rememberme-field"
          # click_on "Sign In"
          click_on "headerLoginButton"
          fill_in "headLoginString", with: config[:gta_user]
          fill_in "headLoginPassword", with: config[:gta_pass]
          check "rememberme"
          begin
            find("button.btn:nth-child(3)").click
          rescue Capybara::Poltergeist::MouseEventFailed
            find("button.btn:nth-child(3)", visible: false).click
          end
          captcha_check 3
          puts "LOGGED IN"
        rescue Capybara::ElementNotFound, Capybara::Ambiguous, Capybara::Poltergeist::MouseEventFailed
          failed
          raise Capybara
        end
      end

      def get_basic_statistics(config, last_time=false)
        read_cookies(page.driver) if not last_time
        page.driver.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36', permanent: true)
        begin
          uri = URI("https://socialclub.rockstargames.com/games/gtav/career/overviewAjax?character=Freemode&nickname=#{config[:tracked_user]}&slot=Freemode&gamerHandle=&gamerTag=&_=1419694640015")
          visit uri
          find("#bank-value")
          return page.body
        rescue Capybara::ElementNotFound, Capybara::Ambiguous
          failed
          return if last_time
          login config
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
          raise Capybara
        rescue Capybara::ElementNotFound
        end
        Capybara.default_max_wait_time = original
      end

      def failed
          puts "FAILURE"
          puts $!
          write_cookies page.driver.browser.cookies
          return
          name = page.save_screenshot
          puts name
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

  def scrape
    begin
      t = MyCapybaraTest::Test.new
      statistics = t.get_basic_statistics @config
      results = parse_page statistics

      #Sorry, but you made too many requests. Please check back in a short while to see if the restriction has been lifted.
      return results
    rescue Capybara
      {}
    end
  end
end
