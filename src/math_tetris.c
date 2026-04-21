#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#define MAX_STRIKES 3
#define LEVELS 10
#define CHOICE_COUNT 4
#define GRID_HEIGHT 15
#define GRID_WIDTH 40
#define EQ_LENGTH 64

// operations
#define ADDITION 0
#define SUBTRACT 1
#define MULTIPLY 2
#define DIVISION 3

int digitCount(int number);
void displayGrid(char grid[GRID_HEIGHT][GRID_WIDTH]);
void generateProblem(int level, int *num1, int *num2, int *target,
                     int options[CHOICE_COUNT], char choices[CHOICE_COUNT], int *operator);
void shuffle(int array[], int size);
char getChoice(char choices[CHOICE_COUNT]);
void clearGrid(char grid[GRID_HEIGHT][GRID_WIDTH]);
void displayEquation(char grid[GRID_HEIGHT][GRID_WIDTH], const char *equation, int x, int y);
int equationTouch(char grid[GRID_HEIGHT][GRID_WIDTH], const char *equation, int x, int y);
int endGame(char grid[GRID_HEIGHT][GRID_WIDTH]);
void equationFormat(char *equation, int num1, int num2, int target, int operator);
char getSymbol(int operator);
void removeEquation(char grid[GRID_HEIGHT][GRID_WIDTH], int x, int y, int length);
void showOptions(int options[CHOICE_COUNT], char choices[CHOICE_COUNT]);

int main(void)
{
    srand((unsigned)time(NULL));

    printf("====================================\n");
    printf(" WELCOME TO MATH TETRIS!\n");
    printf(" Solve equations correctly to win!\n");
    printf(" Get 3 strikes and it's GAME OVER!\n");
    printf("====================================\n\n");

    printf("CONTROLS:\n - Left: press 1\n - Right: press 2\n - Drop: press 3\n");
    printf("(Press ENTER to confirm movement when prompted)\n\n");

    printf("Press ENTER to start...");
    getchar();

    int strikes = 0;
    int score = 0;
    int level = 1;
    int equationsSolved = 0;

    char grid[GRID_HEIGHT][GRID_WIDTH];
    clearGrid(grid);

    while (strikes < MAX_STRIKES && level <= LEVELS)
    {
        printf("\n=== LEVEL %d ===\n\n", level);

        int num1 = 0, num2 = 0, target = 0;
        int options[CHOICE_COUNT] = {0};
        char choices[CHOICE_COUNT] = {'a', 'b', 'c', 'd'};
        int operator = 0;

        // choose operator: easier levels favor addition
        if (level <= 3)
            operator = ADDITION;
        else
        {
            int r = rand() % 100;
            int t1 = 40 - (level * 2);
            int t2 = 70 - (level * 2);
            if (r < t1)
                operator = ADDITION;
            else if (r < t2)
                operator = SUBTRACT;
            else if (r < 90)
                operator = MULTIPLY;
            else
                operator = DIVISION;
        }

        generateProblem(level, &num1, &num2, &target, options, choices, &operator);

        // prepare problem string with a missing value
        char problem[EQ_LENGTH];
        char symbol = getSymbol(operator);
        if (operator == ADDITION || operator == SUBTRACT || operator == MULTIPLY)
        {
            snprintf(problem, sizeof(problem), "%d %c ? = %d", num1, symbol, target);
        }
        else
        {
            snprintf(problem, sizeof(problem), "? %c %d = %d", symbol, num1, target);
        }

        int placeX = (GRID_WIDTH - (int)strlen(problem)) / 2;
        int placeY = 0;
        displayEquation(grid, problem, placeX, placeY);
        displayGrid(grid);

        printf("Solve: %s\n", problem);
        printf("Options: ");
        showOptions(options, choices);

        char userChoice = getChoice(choices);
        int userIndex = -1;
        for (int i = 0; i < CHOICE_COUNT; ++i)
            if (userChoice == choices[i])
                userIndex = i;
        if (userIndex < 0)
            userIndex = 0; // fallback

        int correct_ans = (options[userIndex] == num2);

        char fullEquation[EQ_LENGTH];
        equationFormat(fullEquation, num1, num2, target, operator);

        removeEquation(grid, placeX, placeY, (int)strlen(problem));

        // place the full equation at top center
        placeX = (GRID_WIDTH - (int)strlen(fullEquation)) / 2;
        placeY = 0;
        displayEquation(grid, fullEquation, placeX, placeY);
        displayGrid(grid);

        if (correct_ans)
        {
            printf("CORRECT!\n");
            score += 10 * level;
            equationsSolved++;

            // movement phase
            int moving = 1;
            while (moving)
            {
                printf("Move equation: left (1), right (2), drop (3): ");
                int c = getchar();
                while (c != '\n' && c != EOF)
                {
                    if (c == '1' || c == '2' || c == '3')
                        break;
                    c = getchar();
                }
                // clear leftover line
                while (c != '\n' && c != EOF)
                    c = getchar();

                // remove current
                removeEquation(grid, placeX, placeY, (int)strlen(fullEquation));
                if (c == '1')
                {
                    if (placeX > 0)
                        placeX--;
                    else
                        printf("At left boundary\n");
                }
                else if (c == '2')
                {
                    if (placeX + (int)strlen(fullEquation) < GRID_WIDTH)
                        placeX++;
                    else
                        printf("At right boundary\n");
                }
                else if (c == '3')
                {
                    moving = 0; // drop
                }
                else
                {
                    printf("Invalid input. Use 1, 2 or 3.\n");
                }
                displayEquation(grid, fullEquation, placeX, placeY);
                displayGrid(grid);
            }

            // drop until collision
            int landed = 0;
            while (!landed)
            {
                removeEquation(grid, placeX, placeY, (int)strlen(fullEquation));
                placeY++;
                if (placeY >= GRID_HEIGHT - 1 || equationTouch(grid, fullEquation, placeX, placeY))
                {
                    // step back and place at previous row
                    placeY--;
                    landed = 1;
                }
                displayEquation(grid, fullEquation, placeX, placeY);
                displayGrid(grid);
                if (!landed)
                {
                    printf("Dropping... press ENTER to continue");
                    getchar();
                }
            }
            printf("Equation landed!\n");
        }
        else
        {
            printf("INCORRECT! The correct answer was %d\n", num2);
            strikes++;
            // auto drop the equation to bottom or collision
            int landed = 0;
            while (!landed)
            {
                removeEquation(grid, placeX, placeY, (int)strlen(fullEquation));
                placeY++;
                if (placeY >= GRID_HEIGHT - 1 || equationTouch(grid, fullEquation, placeX, placeY))
                {
                    placeY--;
                    landed = 1;
                }
                displayEquation(grid, fullEquation, placeX, placeY);
                displayGrid(grid);
                if (!landed)
                {
                    printf("Dropping... press ENTER to continue");
                    getchar();
                }
            }
        }

        printf("\n** Score: %d | Level %d | Equations Solved: %d | Strikes %d/%d **\n",
               score, level, equationsSolved, strikes, MAX_STRIKES);

        if (endGame(grid))
        {
            printf("GAME OVER! GRID IS FULL!\n");
            break;
        }

        if (score >= level * 50 && level < LEVELS)
        {
            printf("Advancing to level %d!\n", level + 1);
            level++;
        }

        printf("\nPress ENTER to continue...");
        getchar();
    }

    if (strikes == MAX_STRIKES)
    {
        printf("GAME OVER! %d strikes, YOU'RE OUT!\n", MAX_STRIKES);
    }
    else if (level > LEVELS)
    {
        printf("CONGRATULATIONS! You have completed %d levels and won MATH TETRIS!\n", LEVELS);
    }
    else if (endGame(grid))
    {
        printf("GAME OVER! GRID IS FULL!\n");
    }

    printf("\n===== FINAL STATS =====\n");
    printf("Final Score: %d\n", score);
    printf("Highest Level: %d\n", level);
    printf("Number of Equations Solved: %d\n", equationsSolved);

    return 0;
}

int digitCount(int number)
{
    if (number == 0)
        return 1;
    int count = 0;
    int absVal = number < 0 ? -number : number;
    while (absVal > 0)
    {
        absVal /= 10;
        count++;
    }
    if (number < 0)
        count++; // sign
    return count;
}

void displayGrid(char grid[GRID_HEIGHT][GRID_WIDTH])
{
    printf("\n");
    for (int i = 0; i < GRID_WIDTH + 2; ++i)
        putchar('-');
    putchar('\n');
    for (int r = 0; r < GRID_HEIGHT; ++r)
    {
        putchar('|');
        for (int c = 0; c < GRID_WIDTH; ++c)
            putchar(grid[r][c]);
        putchar('|');
        putchar('\n');
    }
    for (int i = 0; i < GRID_WIDTH + 2; ++i)
        putchar('-');
    putchar('\n');
}

void generateProblem(int level, int *num1, int *num2, int *target,
                     int options[CHOICE_COUNT], char choices[CHOICE_COUNT], int *operator)
{
    int maxNum = 10 + (level * 2);
    if (*operator == ADDITION)
    {
        *num1 = rand() % maxNum + 1;
        *num2 = rand() % maxNum + 1;
        *target = *num1 + *num2;
    }
    else if (*operator == SUBTRACT)
    {
        *num1 = rand() % maxNum + 1;
        *num2 = rand() % maxNum + 1;
        if (*num1 < *num2)
        {
            int t = *num1;
            *num1 = *num2;
            *num2 = t;
        }
        *target = *num1 - *num2;
    }
    else if (*operator == MULTIPLY)
    {
        *num1 = rand() % (maxNum / 2) + 1;
        *num2 = rand() % 10 + 1;
        *target = (*num1) * (*num2);
    }
    else
    { // division
        *num2 = rand() % 10 + 1;
        int mult = rand() % (maxNum / (*num2) + 1) + 1;
        *num1 = (*num2) * mult;
        *target = *num1 / *num2;
    }

    options[0] = *num2; // correct answer is num2
    int leastWrong = 1;
    int mostWrong = maxNum * 2;
    if (*operator == MULTIPLY)
        mostWrong = (*num2) * 2 + 5;

    int i = 1;
    while (i < CHOICE_COUNT)
    {
        int incorrect = leastWrong + rand() % (mostWrong - leastWrong + 1);
        int dupe = 0;
        for (int j = 0; j < i; ++j)
            if (options[j] == incorrect)
            {
                dupe = 1;
                break;
            }
        if (!dupe && incorrect != *num2)
        {
            options[i] = incorrect;
            i++;
        }
    }
    shuffle(options, CHOICE_COUNT);
}

void shuffle(int array[], int size)
{
    for (int i = size - 1; i > 0; --i)
    {
        int j = rand() % (i + 1);
        int t = array[i];
        array[i] = array[j];
        array[j] = t;
    }
}

char getChoice(char choices[CHOICE_COUNT])
{
    char buf[32];
    while (1)
    {
        printf("Enter your choice (%c, %c, %c, %c): ", choices[0], choices[1], choices[2], choices[3]);
        if (!fgets(buf, sizeof(buf), stdin))
            return choices[0];
        // accept first non-space char
        char c = '\0';
        for (size_t i = 0; i < strlen(buf); ++i)
            if (buf[i] != ' ' && buf[i] != '\t' && buf[i] != '\n' && buf[i] != '\r')
            {
                c = buf[i];
                break;
            }
        if (!c)
            continue;
        for (int i = 0; i < CHOICE_COUNT; ++i)
            if (c == choices[i])
                return c;
        printf("Invalid Input: Please enter a, b, c, or d.\n");
    }
}

void clearGrid(char grid[GRID_HEIGHT][GRID_WIDTH])
{
    for (int r = 0; r < GRID_HEIGHT; ++r)
        for (int c = 0; c < GRID_WIDTH; ++c)
            grid[r][c] = ' ';
}

void displayEquation(char grid[GRID_HEIGHT][GRID_WIDTH], const char *equation, int x, int y)
{
    if (y < 0 || y >= GRID_HEIGHT)
        return;
    int len = (int)strlen(equation);
    for (int i = 0; i < len && x + i < GRID_WIDTH; ++i)
    {
        if (x + i >= 0)
            grid[y][x + i] = equation[i];
    }
}

int equationTouch(char grid[GRID_HEIGHT][GRID_WIDTH], const char *equation, int x, int y)
{
    int len = (int)strlen(equation);
    if (y >= GRID_HEIGHT - 1)
        return 1;
    for (int i = 0; i < len; ++i)
    {
        int cx = x + i;
        int cy = y + 1;
        if (cx >= 0 && cx < GRID_WIDTH && cy >= 0 && cy < GRID_HEIGHT)
        {
            if (grid[cy][cx] != ' ')
                return 1;
        }
    }
    return 0;
}

int endGame(char grid[GRID_HEIGHT][GRID_WIDTH])
{
    for (int c = 0; c < GRID_WIDTH; ++c)
        if (grid[0][c] != ' ')
            return 1;
    return 0;
}

void equationFormat(char *equation, int num1, int num2, int target, int operator)
{
    char symbol = getSymbol(operator);
    if (operator == ADDITION || operator == SUBTRACT || operator == MULTIPLY)
    {
        snprintf(equation, EQ_LENGTH, "%d %c %d = %d", num1, symbol, num2, target);
    }
    else
    {
        // division case: show num1 / num2 = target
        snprintf(equation, EQ_LENGTH, "%d %c %d = %d", num1, symbol, num2, target);
    }
}

char getSymbol(int operator)
{
    if (operator == ADDITION)
        return '+';
    if (operator == SUBTRACT)
        return '-';
    if (operator == MULTIPLY)
        return '*';
    return '/';
}

void removeEquation(char grid[GRID_HEIGHT][GRID_WIDTH], int x, int y, int length)
{
    if (y < 0 || y >= GRID_HEIGHT)
        return;
    for (int i = 0; i < length; ++i)
    {
        int cx = x + i;
        if (cx >= 0 && cx < GRID_WIDTH)
            grid[y][cx] = ' ';
    }
}

void showOptions(int options[CHOICE_COUNT], char choices[CHOICE_COUNT])
{
    for (int i = 0; i < CHOICE_COUNT; ++i)
    {
        printf("%c) %d ", choices[i], options[i]);
    }
    printf("\n");
}