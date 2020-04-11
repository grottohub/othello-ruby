# extend Array to include 2.7 tally functionality
# compatible with Ruby v.2.0+
class Array
  def tally
    self.group_by { |row| row }.map { |type, count| [type, count.length] }.to_h
  end
end


# Print out rules
puts "Welcome to Othello but Ruby!\nThis is based off of a high school project I built using Python.\nI am rebuilding it in Ruby to get a better understanding of Rubyist flow control and syntax. Enjoy!"

puts "Rules:\n\tTwo colors(white and black) attempt to dominate the board\n\tConvert your opponents tiles by sandwiching their rows with your tiles\n\tChoose a location by indicating column and row(e.g. A5)"



# GAME SETUP
print "One or two players? "
PLAYER_COUNT = gets.chomp.downcase

$gamemode = { single_player: false }

$current_player = "W"

$error_msg = nil

case PLAYER_COUNT
  when "one" then $gamemode[:single_player] = true
  when "1" then $gamemode[:single_player] = true
  else $gamemode[:single_player] = false
end

$players = Hash.new()

if $gamemode[:single_player]
  ready = false
  until ready
    print "Do you want to be white or black? "
    color = gets.chomp.downcase.match(/w|b/)
    puts "Invalid color, please try again." if !color
    ready = true if color
  end
  $current_player = color.to_s.capitalize
  $computer = $current_player == "W" ? "B" : "W"
  puts "Game is about to start! You chose #{$current_player}."
end

# Define global game variables
$gameboard = {
  A: ['/', '/', '/', '/', '/', '/', '/', '/'],
  B: ['/', '/', '/', '/', '/', '/', '/', '/'],
  C: ['/', '/', '/', '/', '/', '/', '/', '/'],
  D: ['/', '/', '/', 'W', 'B', '/', '/', '/'],
  E: ['/', '/', '/', 'B', 'W', '/', '/', '/'],
  F: ['/', '/', '/', '/', '/', '/', '/', '/'],
  G: ['/', '/', '/', '/', '/', '/', '/', '/'],
  H: ['/', '/', '/', '/', '/', '/', '/', '/']
}

def copy_board
  Marshal.load(Marshal.dump($gameboard))
end

# Make a deep copy (i.e. not pointing to same memory register) for computer simulation
$computer_board = copy_board

def print_board
  print "\t1\s\s2\s\s3\s\s4\s\s5\s\s6\s\s7\s\s8\n"
  $gameboard.each do |row, col|
    print "#{row}\t"
    col.each { |spot| print "#{spot.chomp}\s\s" if !spot.nil? }
    print "\n"
  end
end

$gameover = {
  full_board: false,
  scores: {"W": 0, "B": 0}
}

def check_board
  full_rows = 0
  $gameboard.each do |row, col|
    vals = col.tally
    p vals
    full_rows += 1 if vals["/"].nil?
    unless vals["W"].nil? || vals["B"].nil?
    begin
      $gameover[:scores["W"]] += vals["W"]
      $gameover[:scores["B"]] += vals["B"]
    rescue
    end
    end
  end
  $gameover[:full_board] = true if full_rows == 8
end

def cp_board_check(board)
  cp_count = 0;
  player_count = 0;
  board.each do |row, col|
    vals = col.tally
    cp_count += vals[$computer] if !vals[$computer].nil?
    player_count += vals[$current_player] if !vals[$current_player].nil?
  end
  return [cp_count, player_count]
end

$flip_these = Hash.new()



# GAME LOGIC METHODS
# Method for checking rows(horizontally)
def check_row(row, col, needle, which_board)
  opponent = "W"
  opponent = "B" if needle == "W"
  pushthis = ""
  flipthis = false
  which_board[row][col] = needle
  $flip_these[row] = []
  (col + 1).upto(7) do |spot|
    no_flip = which_board[row][spot + 1] == '/' || which_board[row][spot + 1].nil?
    flip = which_board[row][spot + 1] == needle && spot != 7
    flipthis = flip
    found = which_board[row][spot] == opponent
    pushthis += spot.to_s if found
    break if flip || no_flip
  end
  pushthis.split(//).map { |spot| $flip_these[row].push(spot.to_i) } if flipthis
  pushthis = ""
  flipthis = false
  (col - 1).downto(0) do |spot|
    no_flip = which_board[row][spot - 1] == '/' || which_board[row][spot - 1].nil?
    flip = which_board[row][spot - 1] == needle && spot != 0
    flipthis = flip
    found = which_board[row][spot] == opponent
    pushthis += spot.to_s if found
    break if flip || no_flip
  end
  pushthis.split(//).map { |spot| $flip_these[row].push(spot.to_i) } if flipthis
end

# Method for checking cols(vertically)
def check_col(row, col, needle, which_board)
  opponent = "W"
  opponent = "B" if needle == "W"
  which_board[row][col] = needle
  $flip_these[col] = []
  flipthis = false
  pushthis = ""
  (row.to_s.next).upto("H") do |spot|
    spot = spot.to_sym
    if spot.next != :I
      no_flip = which_board[spot.next][col] == '/'
      flip = which_board[spot.next][col] == needle && spot != :H
      flipthis = flip
      found = which_board[spot][col] == opponent
      pushthis += spot.to_s if found
      break if flip || no_flip
    end
  end
  pushthis.split(//).map { |spot| $flip_these[col].push(spot.to_sym) } if flipthis
  pushthis = ""
  flipthis = false
  reversed = ("A").upto(row.to_s).to_a.reverse
  reversed.each_with_index do |spot, index|
    spot = spot.to_sym
    next_spot = reversed[index + 1].to_sym if !reversed[index + 1].nil?
    if spot != row && !next_spot.nil?
      no_flip = which_board[next_spot][col] == '/' || which_board[next_spot][col].nil?
      flip = which_board[next_spot][col] == needle && spot != :A
      flipthis = flip
      found = which_board[spot][col] == opponent
      pushthis += spot.to_s if found
      break if flip || no_flip
    end
  end
  pushthis.split(//).map { |spot| $flip_these[col].push(spot.to_sym) } if flipthis
end

def is_valid(row, col, which_board)
  # automatically return false if spot is taken
  return false if which_board[row][col] == "W" || which_board[row][col] == "B"

  # Get previous row
  prev_row = nil
  ("A").upto(row.to_s).to_a.reverse.each_with_index { |item, index| prev_row = item if index == 1 }

  # Lambda for adjacency
  is_adjacent = -> (dir) { ["W", "B"].include? dir }

  # Check if adjacent (with a rescue to catch non-existent tiles)
  begin
  # Each adjacent spot empty value
  up = which_board[prev_row.to_sym][col] if !prev_row.nil?
  down = which_board[row.next][col] if row.next != :I
  left = which_board[row][col - 1]
  right = which_board[row][col + 1]
  which_bool = "up"
  up_bool = is_adjacent.call(up)
  which_bool = "down"
  down_bool = is_adjacent.call(down)
  which_bool = "left"
  left_bool = is_adjacent.call(left)
  which_bool = "right"
  right_bool = is_adjacent.call(right)
  main_bool = up_bool || down_bool || left_bool || right_bool
  rescue NoMethodError
    case which_bool
      when "up" then return !(down_bool || left_bool || right_bool)
      when "down" then return !(up_bool || left_bool || right_bool)
      when "left" then return !(down_bool || up_bool || right_bool)
      when "right" then return !(down_bool || left_bool || up_bool)
    end
  end

  return false if !main_bool

  # As long as none of the previous checks were true, it's valid
  return true
end

def flip_tiles(which_color, which_board)
  $flip_these.each do |c_r, spots|
    spots.each do |spot|
      if !spots.empty?
        case c_r.class.to_s
          when "Symbol"
            which_board[c_r][spot] = which_color.to_s
          when "Integer"
            which_board[spot][c_r] = which_color.to_s
          else p c_r.class.to_s
        end
      end
    end
  end
end

# Combines check methods and cleans up flip_these
def check(row, col, needle, which_board)
  if is_valid(row, col, which_board)
    check_row(row, col, needle, which_board)
    check_col(row, col, needle, which_board)
    flip_tiles(needle, which_board)
    $flip_these.clear
  else
    $error_msg = "Invalid spot. Please choose an empty spot adjacent to a token."
  end
end

# Make sure the input contains valid row/col values
def sanitize(input)
  return false if input.length != 2
  row = input.match?(/[a-h]|[A-H]/)
  col = input.match?(/[1-9]/)
  return false if !row || !col
  row = input.match(/[a-h]|[A-H]/).to_s.capitalize.to_sym
  col = input.match(/[1-8]/).to_s.to_i - 1
  return {row: row, col: col}
end

# Swap the current player
def swap_players(player)
  $current_player = "B" if player == "W"
  $current_player = "W" if player == "B"
end

# 1-PLAYER METHODS
def computer_choice
  accuracy = rand(100)

  valid_rows = [:A, :B, :C, :D, :E, :F, :G, :H]
  make_choice = -> { {row: valid_rows[rand(7)], col: rand(7)} }
  choice = make_choice.call()

  possibilities = Hash.new()

  # Base weight off of inverse tangent where computer score is x axis
  calc_weight = -> (comp_score, player_score) { Math.atan2(comp_score, player_score) }

  normal_choice = lambda do
    50.times do
      tmp_choice = make_choice.call()
      tmp_board = copy_board
      until is_valid(tmp_choice[:row], tmp_choice[:col], tmp_board)
        tmp_choice = make_choice.call()
      end
      check(tmp_choice[:row], tmp_choice[:col], $computer, tmp_board)
      compare = cp_board_check(tmp_board)
      weight = calc_weight.call(compare[0], compare[1])
      possibilities[weight] = tmp_choice
    end
    possibilities.sort_by { |weight, tmp| weight }
    average = 0;
    possibilities.each { |weight, tmp| average += weight }
    average /= possibilities.size
    diff = Hash.new()
    possibilities.each { |weight, tmp| diff[(weight - average).abs] = weight }
    diff.sort_by { |weight, proximity| proximity }
    p diff.values
    p possibilities.values
    return possibilities[diff.values.first]
  end

  good_choice = lambda do
    1000.times do
      tmp_choice = make_choice.call()
      tmp_board = copy_board
      until is_valid(tmp_choice[:row], tmp_choice[:col], tmp_board)
        tmp_choice = make_choice.call()
      end
      check(tmp_choice[:row], tmp_choice[:col], $computer, tmp_board)
      compare = cp_board_check(tmp_board)
      weight = calc_weight.call(compare[0], compare[1])
      possibilities[weight] = tmp_choice
    end
    possibilities.sort_by { |weight, tmp| weight }
    return possibilities.values.last
  end


  until is_valid(choice[:row], choice[:col], $computer_board)
    case accuracy
      when 0..25
        choice = make_choice.call()
      when 26..74
        n_choice = normal_choice.call()
        return n_choice
      when 75..100
        return good_choice.call()
    end
  end
  return choice

end


until $gameover[:full_board]

  # Single player logic
  if $gamemode[:single_player]
    print_board if $error_msg.nil?
    puts "#{$error_msg}" if !$error_msg.nil?
    print "Enter a coordinate(#{$current_player}): "
    choice = sanitize(gets.chomp)
    if choice.is_a? Hash
      $error_msg = nil
      check(choice[:row], choice[:col], $current_player, $gameboard)
      #swap_players($current_player) if $error_msg.nil?
      check_board
    else
      $error_msg = "Invalid input. Please try again."
    end
    print_board
    puts "Computer choosing..."
    cc = computer_choice
    check(cc[:row], cc[:col], $computer, $gameboard)
    check_board
  # Two player logic
  else
    print_board if $error_msg.nil?
    puts "#{$error_msg}" if !$error_msg.nil?
    print "Enter a coordinate(#{$current_player}): "
    choice = sanitize(gets.chomp)
    if choice.is_a? Hash
      $error_msg = nil
      check(choice[:row], choice[:col], $current_player, $gameboard)
      swap_players($current_player) if $error_msg.nil?
      check_board
    else
      $error_msg = "Invalid input. Please try again."
    end
  end
end

if $gameover[:scores["W"]] == $gameover[:scores["B"]]
  winner = "it's a tie"
else
  winner = $gameover[:scores["W"]] > $gameover[:scores["B"]] ? "W!" : "B!"
end

puts "And the winner is... #{winner}!"
