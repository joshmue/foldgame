require 'selenium-webdriver'


players = [
  {
    driver: Selenium::WebDriver.for(:chrome),
    name: "Player 1",
    waitt: 0,
    answers: [
      'At the park',
      'Entering something to a textbox on my phone',
      'My dog',
      'Miau!',
      'Woof!',
      'I said: "Well. That one did not make any sense, but often times (and with more players than just 2), these stories make just enough sense to cause amusement!"'
    ]
  },
  {
    driver: Selenium::WebDriver.for(:chrome),
    name: "Player 2",
    waitt: 1,
    answers: [
      'At home',
      'Not much',
      'No one',
      'Is there someone?',
      'No!',
      'I said: "Well. That one did not make any sense, but often times (and with more players than just 2), these stories make just enough sense to cause amusement!"'
    ]
  }
]

players.each do |player|
  player[:driver].get 'https://localhost'
end

sleep 5

def play(player)
  sleep Random.rand(20) * 0.1
  sleep player[:waitt]
  driver = player[:driver]
  namebox = player[:driver].find_element(id: 'nameinput')
  avatarbox = player[:driver].find_element(id: 'avatarinput')
  ok = player[:driver].find_element(class: 'v-btn')

  player[:name].split('').each do |letter|
    namebox.send_keys letter
    sleep 0.01 * Random.rand(10)
  end
  sleep 1
  avatarbox.click
  avatar = driver.find_element(id: 'avatar-fa-running')

  sleep 1

  avatar.click
  sleep 0.4

  ok.click
  sleep 1

  textbox = driver.find_element(id: 'questinput')

  player[:answers].each do |answer|
    wait = Selenium::WebDriver::Wait.new(:timeout => 30)
    wait.until { textbox.enabled? }
    answer.split('').each do |letter|
      textbox.send_keys letter
      sleep 0.00001 * Random.rand(100)
    end
    sleep 0.5
    textbox.send_keys :enter
    sleep 0.5
  end
end

threads = []

players.each do |player|
  threads << Thread.new { play player }
end

threads.each do |thread|
  thread.join
end

sleep 10

players.each do |player|
  player[:driver].quit
end
