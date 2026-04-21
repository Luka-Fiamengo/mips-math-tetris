# Author: Luka Fiamengo 
# Description: Math Tetris Game:
# Players are presented with an algebraic problem and must
select the correct
# answer from multiple choices. If they answer correctly they
gain control of the equation,
# which will be displayed as the complete solution. They can
move left or right or drop it.
# The goal is to position the equations similar to tetris and
the game continues
# until the player reaches 3 strikes, the grid fills up to the
top, the player
# completes all 5 levels.
# DATA SECTION
.data
# Constants (#define in C)
MAX_STRIKES: .word 3
LEVELS: .word 5
CHOICES: .word 4 # Number of answer choice
HEIGHT: .word 15 # Grid Height
WIDTH: .word 40 # Grid Width
WIN_SCORE: .word 300
# Operations
ADDITION: .word 0 SUBTRACT: .word 1
MULTIPLY: .word 2
# Addition operation
# Game Grid (15 row * 40 columns = 600 bytes)
# 2D Grid array (HEIGHT x WIDTH)
# Implemented as a continuous block of memory
grid: .space 600
staticGrid: .space 600 # locked in pieces
# Game State Variables
strikes: .word 0
score: .word 0
level: .word 1
equations_solved: .word 0
# Variables for the Problem
num1: .word 0
num2: .word 0
target: .word 0
operator: .word 0
options: .space 16 # 4 options * 4 bytes
choices: .byte 'a', 'b', 'c', 'd' # Answer choices
# Extra Variables
equation: .space 32 # Space for equation length (at at
least 31 chars + null)
placeX: .word 0
placeY: .word 0
yTable: .word 2, 4, 6, 8, 10, 12, 14
dropCount: .word 0
zeroChar: .byte ' '
# Printed Out Game Messages
welcome_print: .asciiz "====================================\n
WELCOME TO MATH TETRIS! \n Solve equations correctly to win!\n
Get 3 strikes and it's GAME OVER!\n
====================================\n"
controls_print: .asciiz " CONTROLS:\n - Left: Press 1\n -
Right: Press 2\n - Drop: Press 3\n - (MUST CONTINUOUSLY PRESS
UNTIL GROUNDED)\n====================================\n"
rules_print: .asciiz " RULES:\n HAVE FUN AND BE RIGHT!
\n====================================\n"
start_print: .asciiz "Press any key to get started..."
level_msg1: .asciiz "\n=== LEVEL "
level_msg2: .asciiz "===\n\n"
solve_print: .asciiz "Solve: "
opt_print: .asciiz "Options: "
corr_print: .asciiz "CORRECT! "
score_print: .asciiz "\n** Score: "
level_print: .asciiz " | Level: "
eq_solved_print: .asciiz " | Equations Solved: "
strikes_msg1: .asciiz " | Strikes: "
strikes_msg2: .asciiz " **\n"
stats_bar: .asciiz " | |"
moving_print: .asciiz "Move equation: left (L), right (R), or
drop (F): "
left_print: left_bound: DOWN\n"
right_print: right_bound: DOWN\n"
.asciiz " Moving left... "
.asciiz "\nHAVE REACHED LEFT BOUNDARY! MUST MOVE
.asciiz " Moving right... "
.asciiz "\nHAVE REACHED RIGHT BOUNDARY! MUST MOVE
drop_print: .asciiz "\nDropping equation...\n"
invalid_num: .asciiz "\nInvalid input! Use 'L' (left), 'R'
(right), or 'F' (drop).\n"
enter_print: .asciiz "\nPress F\n"
landed_print: .asciiz "Equation landed! "
incorr_print: .asciiz "INCORRECT! The correct answer was "
full_print: .asciiz "GAME OVER! GRID IS STACKED TOO HIGH!"
adv_level_msg1: .asciiz "Advancing to level "
adv_level_msg2: .asciiz "!\n"
continue_print: .asciiz "\nPress ENTER to continue...\n"
max_strike_msg: .asciiz "GAME OVER! 3 strikes, YOU'RE OUT!"
congrats_print: .asciiz "CONGRATULATIONS! You have completed
5 levels and won MATH TETRIS!\n"
stats_print: .asciiz "\n===== FINAL STATS =====\n"
fin_score_msg: .asciiz "Final Score: "
high_level_msg: .asciiz "\nHighest Level: "
num_eq_msg: .asciiz "\nNumber of Equations Solved: "
choice_print: .asciiz "Enter your choice (a, b, c, d):"
invalid_letter: c, or d.\n"
vert_border: .asciiz "|"
horz_border: .asciiz "-"
.asciiz "Invalid Input: Please enter a, b,
fmt1: fmt2: .asciiz "%d %c ? = %d"
.asciiz "? %c %d = %d"
option_sep: .asciiz ") "
newline: .asciiz "\n"
# debug statements
# TEXT SECTION
.text
.globl main
# Main Function For the program
main:
# Print welcome and instructions
li $v0, 4
la $a0, welcome_print
syscall
li $v0, 4
la $a0, controls_print
syscall
li $v0, 4
la $a0, rules_print
syscall
li $v0, 4
la $a0, start_print
syscall
# Wait for key to be pressed
li $v0, 12
syscall
# Initialize game variables
li $t0, 1
sw $t0, level
la $a0, grid
jal clearGrid
sw $zero, strikes
sw $zero, score
li $t0, 1
sw $t0, level
sw $zero, equations_solved
main_loop:
# Check that we are still below 3 strikes and not at last
level
# while (strikes < MAX_STRIKES && level <= LEVELS)
# Write opposite of conditional to jump to a certain place
lw $t0, strikes
lw $t1, MAX_STRIKES($zero)
bge $t0, $t1, game_over
# if (level > LEVELS), the user won
lw $t2, level
lw $t3, LEVELS
bgt $t2, $t3, game_won
lw $t4, score
lw $t5, WIN_SCORE
bge $t4, $t5, game_won
li $v0, 4
la $a0, level_msg1
syscall
li $v0, 1
move $a0, $t2 syscall
# print the current level
li $v0, 4
la $a0, level_msg2
syscall
# Have to use random selection for the other three
operators
li $v0, 42 li $a0, 0
li $a1, 100 syscall
move $t4, $a0 # Random int
# Range 0-99
# t4 = random number 0-99
# Calculate threshold based on level (40 - (level * 2))
li $t5, 40
mul $t6, $t2, 2
sub $t5, $t5, $t6 # t5 = threshold
blt $t4, $t5, use_addition
# Calculate second threshold (70 - (level * 2))
li $t5, 70
mul $t6, $t2, 2
sub $t5, $t5, $t6 blt $t4, $t5, use_subtraction
# t5 = second threshold
li $t5, 90 blt $t4, $t5, use_multiplication
# Third threshold is 90
j use_multiplication
use_addition:
lw $t0, ADDITION
sw $t0, operator
j operator_selected
use_subtraction:
lw $t0, SUBTRACT
sw $t0, operator
j operator_selected
use_multiplication:
lw $t0, MULTIPLY
sw $t0, operator
j operator_selected
operator_selected:
move $a0, $t2 la $a1, num1
la $a2, num2
la $a3, target
# t2 (level) --> $a0
jal generateProblem
lw $a0, operator
jal getSymbol
move $t1, $v0
lw $t2, ADDITION
beq $a0, $t2, format
lw $t2, SUBTRACT
beq $a0, $t2, format
lw $t2, MULTIPLY
beq $a0, $t2, format
#"%d %c ? = %d"
format:
la $a0, equation
lw $a1, num1
move $a2, $t1 getSymbol
lw $a3, target
# t1 is character returned by
jal sprintfProblem
j finish_format
finish_format:
la $a0, equation
jal strlen
move $t0, $v0
# placeX = (WIDTH - strlen(equation)) / 2
lw $t1, WIDTH
sub $t1, $t1, $t0
srl $t2, $t1, 1 li $t3, 0 # t1 has placeX
# placeY = 0
la $a0, grid
la $a1, equation
move $a2, $t2
move $a3, $t3
jal displayEquation
la $a0, grid
jal displayGrid
li $v0, 4
la $a0, solve_print # Solve:
syscall
li $v0, 4
la $a0, equation # %s
syscall
li $v0, 4
la $a0, newline
syscall
# "Options: "
li $v0, 4
la $a0, opt_print
syscall
la $a0, options
la $a1, choices
jal showOptions
# Get user choice
la $a0, choices
jal getChoice
move $t0, $v0 # userChoice stored in t0
# Conver letter into an idex 0-3
li $t5, 'a'
sub $t1, $t0, $t5 # t1 = 0 for a, 1 for b...
la $t2, options sll $t3, $t1, 2
add $t2, $t2, $t3
lw $t4, 0($t2) # base add of options[]
# t4 - options[userSelection]
lw $t5, num2
bne $t4, $t5, incorrect_answer
correct_answer:
li $v0, 31
li $a0, 66
li $a1, 5000
li $a2, 12
li $a3, 100
syscall
li $v0, 4
la $a0, corr_print
syscall
# Update score: score += 10 * level
lw $t0, score
lw $t1, level
li $t3, 10
mul $t3, $t1, $t3 add $t0, $t0, $t3 sw $t0, score
# t3 = 10 * level
# Add to score
# Update equations solved counter
lw $t0, equations_solved
addi $t0, $t0, 1
sw $t0, equations_solved
# jal equationFormat
# Place equation at top of grid with target value (full
equation)
la $a0, equation
jal strlen
move $t0, $v0 # t0 = strlen(equation)
lw $t1, WIDTH
sub $t1, $t1, $t0 strlen(equation)
srl $t1, $t1, 1 sw $t1, placeX # t1 = WIDTH -
# t1 = (WIDTH - strlen) / 2
# Store in placeX
li $t1, 0
sw $t1, placeY # placeY = 0
# Display the equation
la $a0, grid
la $a1, equation
lw $a2, placeX
lw $a3, placeY
jal displayEquation
la $a0, grid
jal displayGrid
j handle_movement
incorrect_answer:
# deep bass tone
li $v0, 33
li $a0, 45 li $a1, 3000 li $a2, 32 # pitch = 45
# 3 s
# acoustic base
li $a3, 100 # volume
syscall
li $v0, 4
la $a0, incorr_print
syscall
# Print correct answer
li $v0, 1
lw $a0, num2
syscall
li $v0, 4
la $a0, newline
syscall
# Increase strike counter
lw $t0, strikes
addi $t0, $t0, 1
sw $t0, strikes
# Place equation at top with target value still marked as ?
la $a0, equation
jal strlen
move $t0, $v0 # t0 = strlen(equation)
lw $t1, WIDTH
sub $t1, $t1, $t0 srl $t1, $t1, 1 sw $t1, placeX # t1 = WIDTH - strlen(equation)
# t1 = (WIDTH - strlen) / 2
# placeX = t1
li $t1, 0
sw $t1, placeY # placeY = 0
# Display the equation
la $a0, grid
la $a1, equation
lw $a2, placeX
lw $a3, placeY
jal displayEquation
la $a0, grid
jal displayGrid
j handle_movement
handle_movement:
li $v0, 4
la $a0, moving_print
syscall
read_move_input:
la $a0, grid
lw $a1, placeX
lw $a2, placeY
move $a3, $t0
jal removeEquation
li $v0, 12
syscall
li $t8, 10 # newline
beq $v0, $t8, read_move_input
li $t9, 13
beq $v0, $t9, read_move_input
move $t0, $v0
move $s0, $t0 # protect it from the jal
la $a0, equation
jal strlen
move $t2, $v0
move $t0, $s0 # restore
li $t1, 76
beq $t0, $t1, handle_left
li $t1, 108
beq $t0, $t1, handle_left
li $t1, 82
beq $t0, $t1, handle_right
li $t1, 114
beq $t0, $t1, handle_right
li $t1, 70
beq $t0, $t1, handle_drop
li $t1, 102
beq $t0, $t1, handle_drop
li $v0, 4
la $a0, invalid_num
syscall
j handle_movement
handle_right:
la $a0, equation
jal strlen
move $t2, $v0
lw $t5, WIDTH
sub $t5, $t5, $t2 # t5 = WIDTH - strlen
lw $t3, placeX
bge $t3, $t5, right_bound_met
addi $t3, $t3, 1
sw $t3, placeX
la $a0, grid
la $a1, equation
lw $a2, placeX
lw $a3, placeY
jal displayEquation
la $a0, grid
jal displayGrid
li $v0, 4
la $a0, right_print
syscall
j handle_movement
right_bound_met:
li $v0, 4
la $a0, right_bound
syscall
# j must_drop
j handle_drop
handle_left:
lw $t3, placeX
blez $t3, left_bound_met
addi $t3, $t3, -1
sw $t3, placeX
la $a0, grid
la $a1, equation
lw $a2, placeX
lw $a3, placeY
jal displayEquation
la $a0, grid
jal displayGrid
li $v0, 4
la $a0, left_print
syscall
j handle_movement
left_bound_met:
li $v0, 4
la $a0, left_bound
syscall
j handle_drop
# j must_drop
handle_drop:
li $v0, 4
la $a0, drop_print
syscall
la $a0, equation
jal strlen
move $t9, $v0 lw $t2, placeX
# t9 = strlen(equation)
li $t3, 0 # t3 = offset in rows (0, 2, 4, and so
on)
li $t4, 14 # bottom row of the grid
scan_slots:
sub $t5, $t4, $t3 bltz $t5, check_bottom # t5 = 14 - offset
# if row < 0 -> fallback
li $t6, 0
lw $t1, WIDTH length - 1
# scan columns from j = 0 to
scan_width:
bge $t6, $t9, row_clear # if j >= length then we know that
it has covered the entire equation
add $t7, $t2, $t6 # column = x + j
la $t8, grid
mul $t0, $t5, $t1 add $t8, $t8, $t0
add $t8, $t8, $t7 # t0 = row * WIDTH
# &grid[row][column]
lb $t7, 0($t8)
li $t0, ' '
bne $t7, $t0, row_not_clear row is blocked
# if it is not a space -> the
addi $t6, $t6, 1 # j++
j scan_width
row_not_clear:
addi $t3, $t3, 2 # next row we check = offset + 2
j scan_slots
row_clear:
sw $t5, placeY # the clear row is now committed
j do_draw
check_bottom:
li $t5, 14
sw $t5, placeY
do_draw:
la $a0, grid
la $a1, equation
lw $a2, placeX
lw $a3, placeY
jal displayEquation
la $a0, grid
jal displayGrid
lw $t4, placeY
# landed
li $t5, 14 beq $t4, $t5, movement_done
# bottom row index = HEIGHT - 1
j movement_done
movement_done:
la $a0, grid
la $a1, equation
lw $a2, placeX
sw $t4, placeY lw $a3, placeY
# ensure Y is committed
jal displayEquation
la $a0, grid
jal displayGrid
li $v0, 4
la $a0, landed_print
syscall
j answer_done
answer_done:
# Display Game Stats
li $v0, 4
la $a0, score_print
syscall
li $v0, 1
lw $a0, score
syscall
li $v0, 4
la $a0, level_print
syscall
li $v0, 1
lw $a0, level
syscall
li $v0, 4
la $a0, eq_solved_print
syscall
li $v0, 1
lw $a0, equations_solved
syscall
li $v0, 4
la $a0, strikes_msg1
syscall
li $v0, 1
lw $a0, strikes
syscall
li $v0, 11
li $a0, 47 # ASCII for '/'
syscall
li $v0, 1
lw $a0, MAX_STRIKES
syscall
li $v0, 4
la $a0, strikes_msg2
syscall
# Check for game over condition
la $a0, grid
jal endGame
beqz $v0, check_level_up # If endGame returns 0 level up
li $v0, 4
la $a0, full_print
syscall
j exit_program
check_level_up:
lw $t0, score
lw $t1, level
mul $t2, $t1, 50 # level * 50
blt $t0, $t2, continue_game
lw $t3, LEVELS
bge $t1, $t3, continue_game
# Level up!
li $v0, 4
la $a0, adv_level_msg1
syscall
li $v0, 1
lw $a0, level
addi $a0, $a0, 1
syscall
li $v0, 4
la $a0, adv_level_msg2
syscall
lw $t0, level
addi $t0, $t0, 1
sw $t0, level
continue_game:
li $v0, 4
la $a0, continue_print
syscall
li $v0, 12
syscall
j main_loop
main_loop_end:
game_over:
# low doom tone
li $v0, 31
li $a0, 30 # frequency
li $a1, 1000 # 1 second
li $a2, 127 # instead of instrument sound
effect
li $a3, 100 # volume
syscall
li $v0, 4
la $a0, max_strike_msg
syscall
j display_final_stats
game_won:
# high victory tone
li $v0, 31
li $a0, 100
li $a1, 500
li $a2, 12 li $a3, 100
syscall
# brighter sound
li $v0, 4
la $a0, congrats_print
syscall
j display_final_stats
display_final_stats:
li $v0, 4
la $a0, stats_print
syscall
li $v0, 4
la $a0, fin_score_msg
syscall
li $v0, 1
lw $a0, score
syscall
li $v0, 4
la $a0, high_level_msg
syscall
li $v0, 1
lw $a0, level
syscall
li $v0, 4
la $a0, num_eq_msg
syscall
li $v0, 1
lw $a0, equations_solved
syscall
li $v0, 4
la $a0, newline
syscall
exit_program:
li $v0, 10
syscall
# FUNCTION
# Initialize the grid with spaces
# $a0: grid base address
# $t0 = row (i)
# $t1 = HEIGHT
# $t2 = WIDTH
# t3 = col (j)
# $t4 = offset
# $t5 = cell address
# $t6 = space char
clearGrid:
li $t0, 0 # i = 0
lw $t1, HEIGHT lw $t2, WIDTH # $t1 = HEIGHT
# $t2 = WIDTH
clear_grid_loop:
bge $t0, $t1, clear_grid_end
li $t3, 0 # j = 0
clear_inner_loop:
bge $t3, $t2, clear_inner_end
# Calculate offset = i * WIDTH + j
mul $t4, $t0, $t2 add $t4, $t4, $t3 addu $t5, $a0, $t4 # i * WIDTH
# i * WIDTH + j
# t5 = base + offset = &grid[i][j]
# Store space character at grid[i][j]
li $t6, ' '
sb $t6, 0($t5) # ASCII code for space
# grid[i][j] = ' '
addi $t3, $t3, 1
j clear_inner_loop
clear_inner_end:
addi $t0, $t0, 1
j clear_grid_loop
clear_grid_end:
jr $ra
# FUNCTION
# Problem that generates the function
# $a0: level (value)
# $a1: address to store num1
# $a2: address to store num2
# $a3: address to store target
generateProblem:
move $t6, $a0
move $t7, $a1
move $t8, $a2
move $t9, $a3
# maxNum - 10 + (level * 2)
li $t0, 2
mul $t1, $t6, $t0
addi $t1, $t1, 10 # maxNum -> t1
lw $t5, operator # t5 = ADD|SUB|MULT|DIV
# Load operator value from stack
lw $t0, ADDITION
beq $t5, $t0, handle_addition
lw $t0, SUBTRACT
beq $t5, $t0, handle_subtract
lw $t0, MULTIPLY
beq $t5, $t0, handle_multiply
j operator_done
handle_addition:
# num1 = rand() % maxNum + 1
li $v0, 42 move $a1, $t1 the random function
syscall # service RandomInt
# maxNum is the upper boundary of
# Randomly generated number is in
$a0
addi $a0, $a0, 1
sw $a0, 0($t7) # store num1
# num2 = rand() % maxNum + 1
li $v0, 42
move $a1, $t1
syscall
addi $a0, $a0, 1
sw $a0, 0($t8) # store num2
# target = num1 + num2
lw $t3, 0($t7) lw $t4, 0($t8) add $t5, $t3, $t4
# t3 -> num1
# t4 -> num2
sw $t5, 0($t9)
j operator_done
handle_subtract:
# num2 = rand() % maxNum + 1
li $v0, 42 move $a1, $t1
syscall
# service RandomInt
addi $a0, $a0, 1
sw $a0, 0($t8) # store num2
# num1 = rand() % maxNum + 1
li $v0, 42
move $a1, $t1
syscall
addi $a0, $a0, 1
sw $a0, 0($t7) # store num1
lw $t3, 0($t7)
lw $t4, 0($t8)
blt $t3, $t4, do_swap
j no_swap
do_swap:
move $t2, $t3 move $t3, $t4 move $t4, $t2 # temp = num1
# num1 = num2
# num2 = temp
sw $t3, 0($t7) sw $t4, 0($t8)
# Should be after swap
no_swap:
# target = num1 - num2
sub $t5, $t3, $t4
sw $t5, 0($t9) # store target
j operator_done
handle_multiply:
# num1 = rand() % (maxNum / 2) + 1
srl $t2, $t1, 1 # maxNum / 2 -> t2 = floor
li $v0, 42
move $a1, $t2 syscall
# set upper bound
addi $a0, $a0, 1
sw $a0, 0($t7)
# num2 = rand() % 10 + 1
li $v0, 42
li $a0, 0
li $a1, 10 syscall
# Set range to be from 0 - 9
addi $a0, $a0, 1 sw $a0, 0($t8)
# Range is now 1 - 10 like in C
# target = num1 * num2
lw $t3, 0($t7)
lw $t4, 0($t8)
mul $t5, $t3, $t4
sw $t5, 0($t9)
j operator_done
operator_done:
# Store the correct answer into options[0]
lw $t6, num2 # t6 -> num2
la $a1, options
sw $t6, 0($a1) # options[0] = num2
# Wrong Answer Range
lw $t6, 0($t9) # target
addi $t2, $t6, -5
ble $t2, $zero, set_min
j set_max
set_min:
li $t2, 1 # leastWrong = 1
set_max:
addi $t3, $t6, 5 # t3 = target + 5
# Fill options[] with unique wrong values
li $t4, 1 # i = 1
wrong_loop:
bge $t4, 4, wrong_done
# Random offset
sub $t0, $t3, $t2 addi $t0, $t0, 1
li $v0, 42
move $a1, $t0
syscall
# t0 -> most - least
add $t0, $a0, $t2 # t0 = incorr = rand range +
leastWrong
li $t8, 0 # j = 0, check against all other
options
dupe_check:
bge $t8, $t4, no_dupe
la $a1, options
sll $a2, $t8, 2
add $a1, $a1, $a2
lw $t7, 0($a1)
beq $t0, $t7, skip_store
addi $t8, $t8, 1 # j++
j dupe_check
no_dupe:
# Compare with the target
lw $t7, 0($t9)
beq $t0, $t7, skip_store
# Store the number into options[i]
la $a1, options
sll $a2, $t4, 2
add $a1, $a1, $a2
sw $t0, 0($a1)
addi $t4, $t4, 1 # i++
skip_store:
j wrong_loop
wrong_done:
# Shuffle the four slots
addi $sp, $sp, -4
sw $ra, 0($sp)
la $a0, options
li $a1, 4
jal shuffle
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
# FUNCTION
# Fisher-Yates Shuffle
# $a0: address of the first element of int array[]
# $a1: size of the array
shuffle:
addi $sp, $sp, -4
sw $ra, 0($sp)
move $t0, $a0 move $t1, $a1
addi $t1, $a1, -1 # t0 = array base
# t1 = i = size - 1
shuffle_loop:
blez $t1, shuffle_done
# j = rand() % (i + 1)
addi $t9, $t1, 1 # bound - i + 1
li $v0, 42
li $a0, 0
move $a1, $t9
syscall
move $t9, $a0 # j = random number
sll $t5, $t1, 2 add $t5, $t0, $t5
lw $t3, 0($t5) # offset i*4
# t3 = array[i]
sll $t6, $t9, 2 add $t6, $t0, $t6
lw $t4, 0($t6) # j * 4
# t4 - array[j]
# Swap array[i] and array[j]
sw $t4, 0($t5) sw $t3, 0($t6) # array[i] = array[j]
# array[j] = array[i]
addi $t1, $t1, -1
j shuffle_loop
shuffle_done:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
# FUNCTION
# Gets the symbol for the current operation
getSymbol:
move $t0, $a0
lw $t1, ADDITION
# Plus
bne $t0, $t1, minus_symbol
li $v0, 43 jr $ra
# Return '+'
minus_symbol:
lw $t1, SUBTRACT
# Minus
bne $t0, $t1, multiply_symbol
li $v0, 45
jr $ra
multiply_symbol:
lw $t1, MULTIPLY
# Multiplication Sign
li $v0, 42
jr $ra
# FUNCTION
# Function format: "%d %c ? = %d"
# $a0 = buffer address
# $a1 = num1
# $a2 = symbol character
# $a3 = target
sprintfProblem:
addi $sp, $sp, -4
sw $ra, 0($sp)
move $t0, $a0
move $a0, $a1
move $a1, $t0
jal integerToString
move $t1, $v0 digits of num1
# t1 = address just past the
li $t2, ' '
sb $t2, 0($t1)
addi $t1, $t1, 1
sb $a2, 0($t1) addi $t1, $t1, 1
# the operator symbol
li $t2, ' '
sb $t2, 0($t1)
addi $t1, $t1, 1
li $t2, '?'
sb $t2, 0($t1)
addi $t1, $t1, 1
li $t2, ' '
sb $t2, 0($t1)
addi $t1, $t1, 1
li $t2, '='
sb $t2, 0($t1)
addi $t1, $t1, 1
li $t2, ' '
sb $t2, 0($t1)
addi $t1, $t1, 1
move $a0, $a3 move $a1, $t1 jal integerToString
move $t1, $v0
# a0 = target
# a1 = bufptr at next free slot
sb $zero, 0($t1)
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
# FUNCTION
# Convert a nonnegative integer in $a0 to a decimal string at
$a1
# Returns in $v0 a pointer to the byte *after* the last digit
(i.e. the first free slot)
# Always null‐terminates the buffer
# Function taken from Payas Krishna
#
https://stackoverflow.com/questions/46917337/simple-mips-functio
n-to-convert-integer-to-string#:~:text=The%20algorithm%20to%20co
nvert%20an,when%20the%20quotient%20is%200.
integerToString:
addi $sp, $sp, -24
sw $ra, 20($sp)
sw $t9, 16($sp)
sw $t8, 12($sp)
sw $t7, 8($sp)
sw $t6, 4($sp)
sw $t5, 0($sp)
move $t9, $a1 move $t1, $a0 # t9 = write pointer into buffer
# t1 = number printing
# Special case 0
beqz $t1, zero_case
# Otherwise, extract digits in reverse order
move $t8, $t9 # t8 = start of digits
conv_loop:
li $t5, 10
div $t1, $t5 mfhi $t6
# HI = remainder, LO = equotient
mflo $t1
addi $t6, $t6, '0' sb $t6, 0($t9) addi $t9, $t9, 1 # ASCII
# store digit
# advance pointer
bnez $t1, conv_loop
j reverse
zero_case:
li $t6, '0'
sb $t6, 0($t9)
addi $t9, $t9, 1
move $t8, $t9 j ready
# treat as 'one digit written'
# reverse the block [t8 ... t9-1]
reverse:
addi $t7, $t9, -1 # t7 = last digit
rev_loop:
blt $t8, $t7, swap_chars
j ready
swap_chars:
lb $t5, 0($t8)
lb $t6, 0($t7)
sb $t6, 0($t8)
sb $t5, 0($t7)
addi $t8, $t8, 1
addi $t7, $t7, -1
j rev_loop
ready:
sb $zero, 0($t9) move $v0, $t9
lw $t5, 0($sp)
lw $t6, 4($sp)
lw $t7, 8($sp)
lw $t8, 12($sp)
lw $t9, 16($sp)
lw $ra, 20($sp)
# null terminator
addi $sp, $sp, 24
jr $ra
# FUNCTION
# USed as strlen in C, to calculate the length of string
# $a0: equation
strlen:
move $t0, $zero # initialize count to start with 1
for first character
strlen_loop:
lb $t1, 0($a0) beqz $t1, strlen_done character is reached
addi $a0, $a0, 1
addi $t0, $t0, 1 # load the next char to t0
# end the loop if null
# increment count
j strlen_loop
strlen_done:
move $v0, $t0
jr $ra
# FUNCTION
# Function to display the equation at a desire location within
the grid
# $a0: grid base address
# $a1: equation string address
# $a2: x position
# $a3: y position
displayEquation:
addi $sp, $sp, -4
sw $ra, 0($sp)
move $t9, $a0 move $a0, $a1 jal strlen
move $t0, $v0 # save grid in t9
# set equation into $a0
# t0 = length
li $t1, 0 # i = 0
display_eq_loop:
# i >= length
bge $t1, $t0, display_eq_done
add $t3, $a2, $t1 lw $t4, WIDTH
# col = x + i
# col >= WIDTH
bge $t3, $t4, display_eq_done
# grid[y][x + 1]
mul $t6, $a3, $t4 add $t6, $t6, $t3 add $t6, $t9, $t6 # t6 = y * WIDTH
# y*W + col
# t6 = &grid[y][x + i]
# load equation[i]
add $t5, $a1, $t1
lb $t5, 0($t5)
# store into grid[y][x + i]
sb $t5, 0($t6)
addi $t1, $t1, 1 # i ++
j display_eq_loop
display_eq_done:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
# FUNCTION
# Used to display the grid on the screen
# $a0: address of grid[0][0]
displayGrid:
move $t9, $a0
# Print a newline
li $v0, 4
la $a0, newline
syscall
lw $t0, WIDTH # 40
lw $t1, HEIGHT # 15
addi $t2, $t0, 2 # t2 = WIDTH + 2
li $t3, 0 # i = 0
top_border_loop:
# Loop condition
bge $t3, $t2, top_border_done
li $v0, 11 li $a0, '-'
syscall
addi $t3, $t3, 1 # Print character syscall
# i++
j top_border_loop
top_border_done:
li $v0, 4
la $a0, newline
syscall
# Middle rows
li $t3, 0 # Reset i to 0 for the next loop
side_border_loop:
# Loop condition
bge $t3, $t1, side_border_done
# Left wall
li $v0, 11
li $a0, '|'
syscall
# Row contents
li $t4, 0 # int k = 0
side_inner_loop:
# Inner loop condition
bge $t4, $t0, side_inner_done
# Calculate the address of grid[i][k]
mul $t5, $t3, $t0 add $t5, $t5, $t4 # i * WIDTH
# (i * WIDTH) + k
addu $t6, $t9, $t5
lb $a0, 0($t6) li $v0, 11
syscall
# Load character from grid[i][k]
addi $t4, $t4, 1 # k++
# Repeat inner loop
j side_inner_loop
side_inner_done:
# Print |\n
li $v0, 11
li $a0, '|'
syscall
li $v0, 4
la $a0, newline
syscall
addi $t3, $t3, 1
# Repeat the outer loop
j side_border_loop
side_border_done:
li $t3, 0
bottom_border_loop:
bge $t3, $t2, bottom_border_done
li $v0, 11
li $a0, '-'
syscall
addi $t3, $t3, 1
j bottom_border_loop
bottom_border_done:
# Print two new lines
li $v0, 4
la $a0, newline
syscall
li $v0, 4
la $a0, newline
syscall
jr $ra
# FUNCTION
# Function used to display options to user
# $a0: options
# $a1: choice
showOptions:
addi $sp, $sp, -4
sw $ra, 0($sp)
# Preserve the array base
move $t8, $a0 # t8 = options base
# print a) <option>
li $v0, 11
li $a0, 'a'
syscall
li $v0, 11
li $a0, ')'
syscall
li $v0, 11
li $a0, ' '
syscall
lw $t0, 0($t8) move $a0, $t0
# t8 = options[0]
li $v0, 1 # print_int
syscall
li $v0, 11
li $a0, ' '
syscall
# print b) <option>
li $v0, 11
li $a0, 'b'
syscall
li $v0, 11
li $a0, ')'
syscall
li $v0, 11
li $a0, ' '
syscall
lw $t0, 4($t8) move $a0, $t0
# t8 = options[1]
li $v0, 1 # print_int
syscall
li $v0, 11
li $a0, ' '
syscall
# print c) <option>
li $v0, 11
li $a0, 'c'
syscall
li $v0, 11
li $a0, ')'
syscall
li $v0, 11
li $a0, ' '
syscall
lw $t0, 8($t8) move $a0, $t0
# t8 = options[2]
li $v0, 1 # print_int
syscall
li $v0, 11
li $a0, ' '
syscall
# print d) <option>
li $v0, 11
li $a0, 'd'
syscall
li $v0, 11
li $a0, ')'
syscall
li $v0, 11
li $a0, ' '
syscall
lw $t0, 12($t8) move $a0, $t0
# t8 = options[3]
li $v0, 1 # print_int
syscall
li $v0, 11
li $a0, ' '
syscall
# final newline
li $v0, 4
la $a0, newline
syscall
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
# FUNCTION
# Recieves the user's choice and validates it
# $a0: choices
getChoice:
addi $sp, $sp, -4
sw $ra, 0($sp)
get_choice_loop:
li $v0, 4
la $a0, choice_print
syscall
li $v0, 12
syscall
move $t0, $v0 # t0 = user's choice
flush_loop:
# drain any extra characters the user might have typed
after the first
li $v0, 12
syscall
li $t1, 10 # '\n'
bne $v0, $t1, flush_loop
# Validate if it is a, b, c, or d
li $t2, 0 # valid = false
li $t3, 'a'
beq $t0, $t3, valid_choice
li $t3, 'b'
beq $t0, $t3, valid_choice
li $t3, 'c'
beq $t0, $t3, valid_choice
li $t3, 'd'
beq $t0, $t3, valid_choice
# bad choice
li $v0, 4
la $a0, invalid_letter
syscall
j get_choice_loop
valid_choice:
move $v0, $t0 # return the valid character
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
# FUNCTION
# Format a complete equation, division is special case
equationFormat:
addi $sp, $sp, -16
sw $ra, 0($sp)
sw $t0, 4($sp)
sw $t1, 8($sp)
sw $t2, 12($sp)
# Load operator coce into a temp
lw $t0, operator move $a0, $t0
# t0 = ADD/SUB/MUL/DIV
jal getSymbol
move $t1, $v0 # t1 = '+', '-', '*', '/'
# Write num1
la $a1, equation
lw $a0, num1
jal integerToString
move $t2, $v0
li $t0, ' '
sb $t0, 0($t2)
addi $t2, $t2, 1
# space
sb $t1, 0($t2) addi $t2, $t2, 1
# write the operator character
li $t0, ' '
# space
sb $t0, 0($t2)
addi $t2, $t2, 1
# Write num2
lw $a0, num2
move $a1, $t2
jal integerToString
move $t2, $v0
li $t0, ' '
sb $t0, 0($t2)
addi $t2, $t2, 1
li $t0, '='
sb $t0, 0($t2)
addi $t2, $t2, 1
li $t0, ' '
sb $t0, 0($t2)
addi $t2, $t2, 1
# Write target
lw $a0, target
move $a1, $t2
jal integerToString
move $t2, $v0
sb $zero, 0($t2)
lw $ra, 0($sp)
lw $t0, 4($sp)
lw $t1, 8($sp)
lw $t2, 12($sp)
addi $sp, $sp, 16
jr $ra
# FUNCTION
# $a0, grid
# $a1, placeX
# $a2, placeY
# $a3 -> strlen(equation)
removeEquation:
addi $sp, $sp, -4
sw $ra, 0($sp)
lw $t0, HEIGHT
bltz $a2, remove_finished
bge $a2, $t0, remove_finished
li $t1, 0 lw $t2, WIDTH
# t1 = i = 0
remove_loop:
bge $t1, $a3, remove_finished
addu $t3, $a1, $t1 bge $t3, $t2, remove_finished
# t3 = x + i
bltz $t3, skip_store_space
# compute grid[y][x + i]
mul $t4, $a2, $t2
add $t4, $t4, $t3
add $t4, $a0, $t4
# store ' ' into grid[y][x + i]
li $t5, ' '
sb $t5, 0($t4)
skip_store_space:
addi $t1, $t1, 1 # i++
j remove_loop
remove_finished:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
# FUNCTION
# Inspect row below to see if the equation can still move
# $a0: grid base
# $a1: equation string address
# $a2: placeX
# $a3: placeY
equationTouch:
la $a0, equation
sb $zero, 0($a0)
li $v0, 0 # assume no collision
touch_loop:
lb $t0, 0($a1)
beq $t0, $zero, done
li $t1, ' '
beq $t0, $t1, skip_char
# compute adress of grid[a3][a2]
lw $t2, WIDTH
mul $t3, $a3, $t2
add $t3, $t3, $a2
add $t3, $t3, $a0
lb $t4, 0($t3)
beq $t4, $t1, skip_char
li $v0, 1
skip_char:
addi $a1, $a1, 1
addi $a2, $a2, 1
j touch_loop
done:
jr $ra
# FUNCTION
# Check the top row for fullness
endGame:
addi $sp, $sp, -4
sw $ra, 0($sp)
la $t1, WIDTH
lw $t1, 0($t1)
li $t2, 0 # i = 0
end_game_loop:
bge $t2, $t1, end_game_false
# Calculate grid[0][i]
add $t3, $a0, $t2
lb $t4, 0($t3)
# Check this: grid[0][i] !+ ' '
li $t5, ' '
bne $t4, $t5, game_finished
addi $t2, $t2, 1
j end_game_loop
game_finished:
li $v0, 1
j end_game_done
end_game_false:
li $v0, 0
end_game_done:
lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
