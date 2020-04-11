# Print out rules
puts "Welcome to Othello but Ruby!\nThis is based off of a high school project I built using Python.\nI am rebuilding it in Ruby to get a better understanding of Rubyist flow control and syntax. Enjoy!"

puts "Rules:\n\tTwo colors(white and black) attempt to dominate the board\n\tConvert your opponents tiles by sandwiching their rows with your tiles\n\tChoose a location by indicating column and row(e.g. A5)"

# Set up game mode
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
    $gameover[:full_board] = true if vals["/"] == 0
    $gameover[:scores["W"]] = vals["W"]
    $gameover[:scores["B"]] = vals["B"]
  end

end

$flip_these = Hash.new()

# Method for checking rows(horizontally)
def check_row(row, col, needle)
  opponent = "W"
  opponent = "B" if needle == "W"
  pushthis = ""
  flipthis = false
  $gameboard[row][col] = needle
  $flip_these[row] = []
  (col + 1).upto(7) do |spot|
    no_flip = $gameboard[row][spot + 1] == '/' || $gameboard[row][spot + 1].nil?
    flip = $gameboard[row][spot + 1] == needle && spot != 7
    flipthis = flip
    found = $gameboard[row][spot] == opponent
    pushthis += spot.to_s if found
    break if flip || no_flip
  end
  pushthis.split(//).map { |spot| $flip_these[row].push(spot.to_i) } if flipthis
  pushthis = ""
  flipthis = false
  (col - 1).downto(0) do |spot|
    no_flip = $gameboard[row][spot - 1] == '/' || $gameboard[row][spot - 1].nil?
    flip = $gameboard[row][spot - 1] == needle && spot != 0
    flipthis = flip
    found = $gameboard[row][spot] == opponent
    pushthis += spot.to_s if found
    break if flip || no_flip
  end
  pushthis.split(//).map { |spot| $flip_these[row].push(spot.to_i) } if flipthis
end

# Method for checking cols(vertically)
def check_col(row, col, needle)
  opponent = "W"
  opponent = "B" if needle == "W"
  $gameboard[row][col] = needle
  $flip_these[col] = []
  flipthis = false
  pushthis = ""
  (row.to_s.next).upto("H") do |spot|
    spot = spot.to_sym
    if spot.next != :I
      no_flip = $gameboard[spot.next][col] == '/'
      flip = $gameboard[spot.next][col] == needle && spot != :H
      flipthis = flip
      found = $gameboard[spot][col] == opponent
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
      no_flip = $gameboard[next_spot][col] == '/' || $gameboard[next_spot][col].nil?
      flip = $gameboard[next_spot][col] == needle && spot != :A
      flipthis = flip
      found = $gameboard[spot][col] == opponent
      pushthis += spot.to_s if found
      break if flip || no_flip
    end
  end
  pushthis.split(//).map { |spot| $flip_these[col].push(spot.to_sym) } if flipthis
end

def is_valid(row, col)
  # automatically return false if spot is taken
  return false if $gameboard[row][col] == "W" || $gameboard[row][col] == "B"

  # Get previous row
  prev_row = nil
  ("A").upto(row.to_s).to_a.reverse.each_with_index { |item, index| prev_row = item if index == 1 }

  # Lambda for adjacency
  is_adjacent = -> (dir) { ["W", "B"].include? dir }

  # Check if adjacent (with a rescue to catch non-existent tiles)
  begin
  # Each adjacent spot empty value
  up = $gameboard[prev_row.to_sym][col] if !prev_row.nil?
  down = $gameboard[row.next][col] if row.next != :I
  left = $gameboard[row][col - 1]
  right = $gameboard[row][col + 1]
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

def flip_tiles(which)
  $flip_these.each do |c_r, spots|
    spots.each do |spot|
      if !spots.empty?
        case c_r.class.to_s
          when "Symbol"
            $gameboard[c_r][spot] = which.to_s
          when "Integer"
            $gameboard[spot][c_r] = which.to_s
          else p c_r.class.to_s
        end
      end
    end
  end
end

# Combines check methods and cleans up flip_these
def check(row, col, needle)
  if is_valid(row, col)
    check_row(row, col, needle)
    check_col(row, col, needle)
    flip_tiles(needle)
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

until $gameover[:full_board]

  # Single player logic
  if $gamemode[:single_player]
    puts "Not implemented"
    $gameover[:full_board] = true
  # Two player logic
  else
    print_board if $error_msg.nil?
    puts "#{$error_msg}" if !$error_msg.nil?
    print "Enter a coordinate(#{$current_player}): "
    choice = sanitize(gets.chomp)
    if choice.is_a? Hash
      $error_msg = nil
      check(choice[:row], choice[:col], $current_player)
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
