 require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'frisco'

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
  def calculate_total(cards)
    arr = cards.map{ |card|  card[1] }

    total = 0
    arr.each do |val|
      if val == "A"
        total += 11
      else
        total += (val.to_i == 0 ? 10 : val.to_i)
      end
    end

    #correct for Aces
    arr.select{|val| val == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def display_card(card)
    suit = case
      when card[0] == "C" 
        "clubs_"
      when card[0] == "D" 
        "diamonds_"
      when card[0] == "H" 
        "hearts_"
      when card[0] == "S" 
        "spades_"
      end
    face = case
      when card[1] == "2" 
        "2"
      when card[1] == "3" 
        "3"
      when card[1] == "4" 
        "4"
      when card[1] == "5" 
        "5"
      when card[1] == "6" 
        "6"
      when card[1] == "7" 
        "7"
      when card[1] == "8" 
        "8"
      when card[1] == "9" 
        "9"
      when card[1] == "10" 
        "10"
      when card[1] == "J" 
        "jack"
      when card[1] == "Q" 
        "queen"
      when card[1] == "K" 
        "king"
      when card[1] == "A" 
        "ace"
      end
      
      filename = suit.to_s + face.to_s + '.jpg'
  end
end


before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else 
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Please enter your name."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game_over' do
  erb :game_over
end

get '/game' do
  suits = ['H', 'D', 'C', 'S']
  values =  ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
    @blackjack = "Blackjack, you won!"
    @show_hit_or_stay_buttons = false
  end

  if calculate_total(session[:dealer_cards]) == BLACKJACK_AMOUNT
    @dealer_blackjack = "Dealer gets Blackjack! You lose!"
    @show_hit_or_stay_buttons = false
  end
 
  erb :game 
end

post '/game/player/hit' do
  @hit = true
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
    @blackjack = "Blackjack, you won!"
    @show_hit_or_stay_buttons = false
    @play_again = true
  elsif calculate_total(session[:player_cards]) > BLACKJACK_AMOUNT
    @error = "Sorry, you busted!" 
    @show_hit_or_stay_buttons = false
    @play_again = true
  end
  erb :game
end

post '/game/player/stay' do
  @stay = "You decided to stay."
  @show_hit_or_stay_buttons = false
  @show_next_dealer_card = true
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  @show_hit_or_stay_buttons = false
  @show_next_dealer_card = true
  if calculate_total(session[:dealer_cards]) == BLACKJACK_AMOUNT
    @dealer_blackjack = "Dealer gets Blackjack! You lose!"
    @show_next_dealer_card = false
    @play_again = true
  elsif calculate_total(session[:dealer_cards]) > BLACKJACK_AMOUNT
    @dealer_busts = "Dealer busts. You win!" 
    @show_next_dealer_card = false
    @play_again = true
  elsif calculate_total(session[:dealer_cards]) >= DEALER_MIN_HIT
    if calculate_total(session[:dealer_cards]) > calculate_total(session[:player_cards])
      @dealer_wins = "Dealer wins."
      @show_next_dealer_card = false
      @play_again = true
    else
      @dealer_loses = "You win!"
      @show_next_dealer_card = false
      @play_again = true
    end
  end
    erb :game
end
