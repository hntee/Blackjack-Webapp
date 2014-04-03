require 'rubygems'
require 'sinatra'
require 'pry'
set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_STOP_HIT = 17

helpers do
  def calculate_total(cards) 
    # [['H', '3'], ['S', 'Q'], ... ]
    arr = cards.map{|e| e[1] }

    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end

    #correct for Aces
    arr.select{|e| e == "A"}.count.times do
      total -= 10 if total > BLACKJACK_AMOUNT
    end

    total
  end

  def get_file_name card
    suit = card[0]
    value = card[1]

    suit = case card[0] # suit
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'S' then 'spades'
      when 'C' then 'clubs'
    end

    value = case card[1] # value
      when 'A' then 'ace'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'J' then 'jack'
      else card[1].to_i
    end

    "#{suit}_#{value}.jpg"
  end

  def winner!(msg)
    @success = "#{session[:player_name]} wins $#{session[:bet_money]}! #{msg}"
    @show_hit_or_stay_button = false
    @show_play_again_button = true
  end
  
  def loser!(msg)
    @error = "#{session[:player_name]} loses $#{session[:bet_money]}! #{msg}"
    @show_hit_or_stay_button = false 
    @show_play_again_button = true
  end
  
  def tie!
    @tie = "It's a tie!"
    @show_hit_or_stay_button = false
    @show_play_again_button = true
  end
  
end

before do
  @show_hit_or_stay_button = true
  @dealer_hit = false
  @show_play_again_button = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_game'
  end
end

get '/game' do
  redirect '/new_game' if !session[:player_name]

  session[:turn] = session[:player]

  suits = ['H', 'D', 'S', 'C']
  cards = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

  session[:deck] = suits.product(cards).shuffle!

  session[:playercards] = []
  session[:dealercards] = []

  # deal cards
  session[:playercards] << session[:deck].pop
  session[:dealercards] << session[:deck].pop
  session[:playercards] << session[:deck].pop
  session[:dealercards] << session[:deck].pop

  if calculate_total(session[:playercards]) == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
    session[:total_money] += 2 * session[:bet_money] 


  end

  erb :game

end

get '/new_game' do
  session.clear
  session[:total_money] = 500
  erb :set_name_form
end

post '/new_game' do
  if params[:player_name].empty?
    @error = 'The name cannot be empty!'
    erb :set_name_form
  elsif params[:player_name].match(/[^a-zA-Z ]/)
    @error = 'The name cannot be non-alphabetical characters!'
    erb :set_name_form
  else
    session[:player_name] = params[:player_name]
    redirect '/bet'
  end
end

get '/bet' do
  if session[:player_name].class == NilClass
    redirect '/'
  end

  session[:total_money] ||= 500
  session[:bet_money] = ''
  erb :bet
end

post '/bet' do
  session[:bet_money] = params[:bet_money]

  # validate the input
  # have non-digit char or space or is empty
  if session[:bet_money].match(/[^\d]|\s/) || session[:bet_money].empty? ||session[:bet_money].to_i == 0
    @error = "Error. You should bet at least one dollar"
    erb :bet
  else
    # convert to an integer
    session[:bet_money] = session[:bet_money].to_i

    if session[:bet_money] > session[:total_money]
      @error = "You don't have enough money!"
      erb :bet
    else
      session[:total_money] -= session[:bet_money]
      redirect '/game'
    end
  end
end

post '/game/player/hit' do
  session[:playercards] << session[:deck].pop
  if calculate_total(session[:playercards]) == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
    session[:total_money] += 2 * session[:bet_money] 
  elsif calculate_total(session[:playercards]) > BLACKJACK_AMOUNT
    loser!("#{session[:player_name]} busted at #{calculate_total(session[:playercards])}." )
  end

  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"

  dealerpoints = calculate_total(session[:dealercards])
  @show_hit_or_stay_button = false

  if dealerpoints == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack!")

  elsif dealerpoints > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealerpoints}.")
    session[:total_money] += 2 * session[:bet_money] 

  elsif dealerpoints >= DEALER_STOP_HIT
    redirect '/game/compare'
  else
    @dealer_hit = true
  end
  
  erb :game
end

post '/game/dealer/hit' do
  session[:dealercards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game_over' do
  erb :game_over
end

get '/game/compare' do
  @show_hit_or_stay_button = false

  dealer_total = calculate_total(session[:dealercards])
  player_total = calculate_total(session[:playercards])

  if dealer_total > player_total
    loser!("Dealer has #{dealer_total} and #{session[:player_name]} has #{player_total}.")

  elsif dealer_total < player_total
    winner!("Dealer has #{dealer_total} and #{session[:player_name]} has #{player_total}.")
    session[:total_money] += 2 * session[:bet_money] 

  else
    tie!
    session[:total_money] += session[:bet_money] 
  end

  erb :game
end
