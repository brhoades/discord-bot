require 'mechanize'
require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'


Capybara.default_wait_time = 5
Capybara.run_server = false
Capybara.current_driver = :poltergeist
# Capybara.app_host = 'http://soc'
uri = URI('https://socialclub.rockstargames.com/profile/signin')

module MyCapybaraTest
  class Test
    include Capybara::DSL
    def get_basic_statistics
      uri = URI('https://socialclub.rockstargames.com/profile/signin')
      visit uri
      fill_in "login-field", with: ENV["GTA_USER"]
      fill_in "password-field", with: ENV["GTA_PASS"]
      check "rememberme"
      click_on "Sign In"
      visit "https://socialclub.rockstargames.com/games/gtav/career/overviewAjax?character=Freemode&nickname=foukemonster&slot=Freemode&gamerHandle=&gamerTag=&_=1419694640015"
      statistics = page.body

      return statistics
    end
  end
end

t = MyCapybaraTest::Test.new
t.test_google
exit
