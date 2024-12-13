INPUT_FILE_PATH = 'input.txt'
STONE_COUNT_CACHE = {}

def compute_stone_count(stone: int, iterations: int) -> int:
    if iterations == 0:
        return 1
    if (stone, iterations) in STONE_COUNT_CACHE:
        return STONE_COUNT_CACHE[(stone, iterations)]

    if stone == 0:
        count = compute_stone_count(1, iterations - 1)
        STONE_COUNT_CACHE[(stone, iterations)] = count
        return count

    digits = str(stone)
    if len(digits) % 2 == 0:
        count = compute_stone_count(int(digits[len(digits)//2:]), iterations - 1)
        count += compute_stone_count(int(digits[:len(digits)//2]), iterations - 1)
        STONE_COUNT_CACHE[(stone, iterations)] = count
        return count

    count = compute_stone_count(stone * 2024, iterations - 1)
    STONE_COUNT_CACHE[(stone, iterations)] = count
    return count

def task1(stones: list[int]):
    result = sum(compute_stone_count(stone, 25) for stone in stones)
    print(f'Task1 = { result }')

def task2(stones: list[int]):
    result = sum(compute_stone_count(stone, 75) for stone in stones)
    print(f'Task2 = { result }')

if __name__ == '__main__':
    with open(INPUT_FILE_PATH, 'r') as file:
        initial_stones = [int(stone) for stone in file.read().split(' ')]
    task1(initial_stones)
    task2(initial_stones)
