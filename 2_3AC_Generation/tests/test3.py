
class Solution:
    
    # Function to print grids of the Sudoku.
    def __init__(self):
        self.name:str="mySudoku"

    def printGrid(self, arr: list[list[int]]) -> None:
        i:int
        j:int
        for i in range(9):
            for j in range(9):
                print(arr[i][j])
            print("")

    # Function to return a boolean which indicates whether an assigned  
    # entry in the specified row matches the given number. 
    def used_in_row(self, arr: list[list[int]], row: int, num: int) -> bool:
        i:int
        for i in range(9):
            if arr[row][i] == num:
                return True
        return False

    # Function to return a boolean which indicates whether an assigned  
    # entry in the specified column matches the given number.
    def used_in_col(self, arr: list[list[int]], col: int, num: int) -> bool:
        i:int
        for i in range(9):
            if arr[i][col] == num:
                return True
        return False

    # Function to return a boolean which indicates whether an assigned
    # entry within the specified 3x3 box matches the given number.
    def used_in_box(self, arr: list[list[int]], row: int, col: int, num: int) -> bool:
        i:int
        j:int
        for i in range(3):
            for j in range(3):
                if arr[i + row][j + col] == num:
                    return True
        return False

    # Function to return a boolean which indicates whether it will be 
    # legal to assign num to the given row, column location. 
    def check_location_is_safe(self, arr: list[list[int]], row: int, col: int, num: int) -> bool:
        return not self.used_in_row(arr, row, num) and not self.used_in_col(arr, col, num) and not self.used_in_box(arr, row - row % 3, col - col % 3, num)

    def find_empty_location(self, arr: list[list[int]], l: list[int]) -> bool:
        row:int
        col:int
        for row in range(9):
            for col in range(9):
                if arr[row][col] == 0:
                    l[0] = row
                    l[1] = col
                    return True
        return False

    # Function to find a solved Sudoku. 
    def SolveSudoku(self, grid: list[list[int]]) -> bool:
        l :list[int]= [0, 0]

        # If there is no unassigned location, we are done.
        if not self.find_empty_location(grid, l):
            return True

        row :int= l[0]
        col :int= l[1]

        # Considering digits from 1 to 9  
        num:int
        for num in range(1, 10):

            if self.check_location_is_safe(grid, row, col, num):

                # Making tentative assignment 
                grid[row][col] = num
                # If success, return true 
                if self.SolveSudoku(grid):
                    return True
                # Failure, unmake & try again 
                grid[row][col] = 0

        # This triggers backtracking 
        return False

def main() -> None:
    sudoku :list[list[int]]= [
        [3, 0, 6, 5, 0, 8, 4, 0, 0],
        [5, 2, 0, 0, 0, 0, 0, 0, 0],
        [0, 8, 7, 0, 0, 0, 0, 3, 1],
        [0, 0, 3, 0, 1, 0, 0, 8, 0],
        [9, 0, 0, 8, 6, 3, 0, 0, 5],
        [0, 5, 0, 0, 9, 0, 6, 0, 0],
        [1, 3, 0, 0, 0, 0, 2, 5, 0],
        [0, 0, 0, 0, 0, 0, 0, 7, 4],
        [0, 0, 5, 2, 0, 6, 3, 0, 0]
    ]
    sol :Solution= Solution()
    if sol.SolveSudoku(sudoku):
        print("Solution found:")
        sol.printGrid(sudoku)
    else:
        print("No solution exists.")

if __name__ == "__main__":
    main()

#source: https://www.geeksforgeeks.org/problems/solve-the-sudoku-1587115621/1?page=1&difficulty=Hard&sprint=a663236c31453b969852f9ea22507634&sortBy=submissions
