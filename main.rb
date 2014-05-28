require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_HIT_MIN = 17

helpers do #calculate total

  def calculate_total(cards)
    arr = cards.map { |x| x[1]}
  
    total = 0
  
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0
        total += 10
      else
        total += value.to_i
      end
    end
  
    #Figure out if Ace is worth 11 or 1
    arr.select { |x| x == "A"}.count.times do
      total -= 10 if total > BLACKJACK_AMOUNT
    end
  
    total
  end

  def card_image(card)
    suit = case card[0]
      when "H" then "hearts"
      when "D" then "diamonds"
      when "C" then "clubs"
      when "S" then "spades"
    end

    value = card[1]
    if ["J", "Q", "K", "A"].include?(value)
      value = case card[1]
        when "J" then "jack"
        when "Q" then "queen"
        when "K" then "king"
        when "A" then "ace"
      end
    end
  "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'/>"
  end

  def winner!(message)
    @winner = "<strong>#{session[:new_user]} wins!</strong> #{message}"
    session[:money] = session[:money] + session[:player_bet]
  end

  def loser!(message)
    @loser = "<strong>#{session[:new_user]} loses. #{message}"
    session[:money] = session[:money] - session[:player_bet]
  end

  def tie!(message)
    @winner = "<strong>It's a tie!</tie> #{message}"
  end
end



before do
  @show_hit_or_stay = true
  @play_again = false
  @dealers_turn = false
end


get "/" do
  if session[:player_name]
    redirect "/game"
  else
    redirect "/new_user"
  end
end

get "/new_user" do
  session[:money] = 500
  erb :new_user
end

post "/new_user" do
  if params[:new_user].empty?
    @loser = "Name is required"
    halt erb(:new_user)
  end

  session[:new_user] = params[:new_user]
  redirect "/betting"
end

get "/betting" do
  session[:player_bet] = nil
  erb :betting
end

post "/betting" do

  if params[:betting].nil? || params[:betting].to_i == 0
    @loser = "Must make a bet"
    halt erb(:betting)
  elsif params[:betting].to_i > session[:money]
    @loser = "Betting amount can not be greater than what you have ($" + session[:money].to_s + ")"
    halt erb(:betting)
  else
    session[:player_bet] = params[:betting].to_i
  end

  redirect "/game"

end

get "/game" do
  session[:turn] = session[:new_user]

  #First you need to initialize deck, deal cards(player and dealer)
  #create a deck and put it into session
  suits = ["H", "D", "S", "C"]
  values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
  session[:deck] = suits.product(values).shuffle!

  #deal cards to player and dealer
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("You got BLACKJACK!!")
    @show_hit_or_stay = false
    @play_again = true
  end

  erb :game
end

post "/game/player/hit" do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total > BLACKJACK_AMOUNT
    loser!("You went over 21! BUST!")
    @show_hit_or_stay = false
    @play_again = true

  elsif player_total == BLACKJACK_AMOUNT
    winner!("You got BLACKJACK!!")
    @show_hit_or_stay = false
    @play_again = true
  end

  erb :game, layout: false
end

get "/game/dealers_turn" do
  session[:turn] = "dealer"
  @show_hit_or_stay = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit 21 which means you lose!")
    @play_again = true
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("The dealer busted!")
    @play_again = true
  elsif dealer_total >= DEALER_HIT_MIN
    #dealer stays
    redirect "/game/compare"
  else
    #dealer hits
    @dealers_turn = true
  end

  erb :game, layout: false
end

post "/game/player/stay" do
  @winner = session[:new_user] + " has chosen to stay"
  @show_hit_or_stay = false
  @play_again = true
  @dealers_turn = true
  redirect "/game/dealers_turn"
end

post "/game/play_again/yes" do
  if session[:money] == 0
    redirect "/sorry"
  end
  redirect "/betting"
end

get "/sorry" do
  erb :sorry
end

post "/game/play_again/no" do
  erb :thank
end

post "/game/dealer_hit" do
  session[:dealer_cards] << session[:deck].pop
  redirect "/game/dealers_turn"
end

get "/game/compare" do
  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])
  @show_hit_or_stay = false
  if player_total > dealer_total
    winner!("You won, with a final score of #{player_total} to #{dealer_total}!")
    @play_again = true
  elsif player_total < dealer_total
    loser!("You lost, with a final score of #{dealer_total} to #{player_total}!")
    @play_again = true
  else
    tie!("You tied, with a final score of #{dealer_total} to #{player_total}!")
    @play_again = true
  end

  erb :game, layout: false
end









