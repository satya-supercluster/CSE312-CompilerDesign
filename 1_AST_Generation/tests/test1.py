# Python Implementation of the Quick Sort Algorithm.

def swap(arr: list[int], a: int, b: int) -> None:
    temp: int = arr[a]
    arr[a] = arr[b]
    arr[b] = temp

def partition(arr: list[int], start: int, end: int) -> int:
    pivot: int = arr[start]
    count: int = 0
    i:int
    for i in range(start + 1, end + 1):
        if arr[i] <= pivot:
            count += 1
    # Giving pivot element its correct position
    pivotIndex: int = start + count
    swap(arr, pivotIndex, start)

    # Sorting left and right parts of the pivot element
    i=start
    j: int = end

    while i < pivotIndex and j > pivotIndex:
        while arr[i] <= pivot:
            i += 1
        while arr[j] > pivot:
            j -= 1
        if i < pivotIndex and j > pivotIndex:
            swap(arr, i, j)
            i += 1
            j -= 1

    return pivotIndex

def quickSort(arr: list[int], start: int, end: int) -> None:

    # base case
    if start >= end:
        return

    # partitioning the array
    p: int = partition(arr, start, end)
    # Sorting the left part
    quickSort(arr, start, p - 1)
    # Sorting the right part
    quickSort(arr, p + 1, end)


def main():
    arr: list[int] = [9, 3, 4, 2, 1, 8]
    n: int = len(arr)
    quickSort(arr, 0, n - 1)
    i:int
    for i in range(n):
        print(arr[i])

if __name__ == "__main__":
    main()
