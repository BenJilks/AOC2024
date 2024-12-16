package main

import (
    "bufio"
    "fmt"
    "os"
)

type Cell int
const (
    CellEmpty = Cell(iota)
    CellWall
    CellBox
    CellBoxLeft
    CellBoxRight
)

type Move int
const (
    MoveUp = Move(iota)
    MoveDown
    MoveLeft
    MoveRight
)

type Warehouse struct {
    grid []Cell
    width int
    height int

    robot_x int
    robot_y int
    moves []Move
}

func decode_cell(char rune) Cell {
    switch char {
    case '#':
        return CellWall
    case 'O':
        return CellBox
    default:
        return CellEmpty
    }
}

func decode_move(char rune) Move {
    switch char {
    case '^':
        return MoveUp;
    case 'v':
        return MoveDown;
    case '<':
        return MoveLeft;
    case '>':
        return MoveRight;
    default:
        panic("Invalid move");
    }
}

func task1_line_decoder(warehouse *Warehouse, line string) {
    for x, char := range line {
        cell := decode_cell(char)
        warehouse.grid = append(warehouse.grid, cell)

        if char == '@' {
            warehouse.robot_x = x
            warehouse.robot_y = warehouse.height
        }
    }

    warehouse.width = len(line)
    warehouse.height += 1
}

func task2_line_decoder(warehouse *Warehouse, line string) {
    for x, char := range line {
        cell := decode_cell(char)
        if cell == CellBox {
            warehouse.grid = append(warehouse.grid, CellBoxLeft, CellBoxRight)
        } else {
            warehouse.grid = append(warehouse.grid, cell, cell)
        }

        if char == '@' {
            warehouse.robot_x = x * 2
            warehouse.robot_y = warehouse.height
        }
    }

    warehouse.width = len(line) * 2
    warehouse.height += 1
}

func read_input(
    file_path string,
    line_decoder func(*Warehouse, string),
) (Warehouse, error) {
    file, err := os.Open(file_path)
    if err != nil {
        return Warehouse {}, err
    }
    defer file.Close()

    warehouse := Warehouse {}
    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        line := scanner.Text()
        if len(line) == 0 {
            break
        }

        line_decoder(&warehouse, line)
    }

    for scanner.Scan() {
        line := scanner.Text()
        for _, char := range line {
            warehouse.moves = append(warehouse.moves, decode_move(char));
        }
    }

    return warehouse, nil
}

func (cell Cell) joining_cell_offset() (bool, int) {
    switch (cell) {
    case CellBoxLeft:
        return true, 1
    case CellBoxRight:
        return true, -1
    default:
        return false, 0
    }
}

func (move Move) direction() (int, int) {
    switch move {
    case MoveUp:
        return 0, -1
    case MoveDown:
        return 0, 1
    case MoveLeft:
        return -1, 0
    case MoveRight:
        return 1, 0
    default:
        panic("Invalid move")
    }
}

func (warehouse *Warehouse) is_in_bounds(x int, y int) bool {
    return x >= 0 && x < warehouse.width && y >= 0 && y < warehouse.height
}

func (warehouse *Warehouse) at(x int, y int) Cell {
    if !warehouse.is_in_bounds(x, y) {
        return CellWall
    }
    return warehouse.grid[y * warehouse.width + x]
}

func (warehouse *Warehouse) set(x int, y int, cell Cell) {
    if warehouse.is_in_bounds(x, y) {
        warehouse.grid[y * warehouse.width + x] = cell
    }
}

func (warehouse *Warehouse) check_push(x int, y int, move Move) bool {
    cell := warehouse.at(x, y)
    switch cell {
    case CellEmpty:
        return true
    case CellWall:
        return false
    case CellBox, CellBoxLeft, CellBoxRight:
        dx, dy := move.direction()
        has_joining, joining_x := cell.joining_cell_offset()
        if has_joining && (move == MoveUp || move == MoveDown) {
            if !warehouse.check_push(x + joining_x + dx, y + dy, move) {
                return false
            }
        }

        return warehouse.check_push(x + dx, y + dy, move)
    default:
        panic("Invalid cell")
    }
}

func (warehouse *Warehouse) move_cell(x int, y int, dx int, dy int) {
    cell := warehouse.at(x, y)
    warehouse.set(x, y, CellEmpty)
    warehouse.set(x + dx, y + dy, cell)
}

func (warehouse *Warehouse) push(x int, y int, move Move) {
    cell := warehouse.at(x, y)
    switch cell {
    case CellEmpty:
        break
    case CellBox, CellBoxLeft, CellBoxRight:
        dx, dy := move.direction()
        has_joining, joining_x := cell.joining_cell_offset()
        if has_joining && (move == MoveUp || move == MoveDown) {
            warehouse.push(x + joining_x + dx, y + dy, move)
            warehouse.move_cell(x + joining_x, y, dx, dy)
        }

        warehouse.push(x + dx, y + dy, move)
        warehouse.move_cell(x, y, dx, dy)
    default:
        panic("Invalid cell")
    }
}

func (warehouse *Warehouse) do_move(move Move) {
    dx, dy := move.direction()
    new_x := warehouse.robot_x + dx
    new_y := warehouse.robot_y + dy
    if warehouse.check_push(new_x, new_y, move) {
        warehouse.push(new_x, new_y, move)
        warehouse.robot_x = new_x
        warehouse.robot_y = new_y
    }
}

func (warehouse *Warehouse) compute_score() int {
    total_score := 0
    for y := 0; y < warehouse.height; y++ {
        for x := 0; x < warehouse.width; x++ {
            cell := warehouse.at(x, y)
            if cell == CellBox || cell == CellBoxLeft {
                total_score += 100 * y + x
            }
        }
    }

    return total_score
}

func do_task(line_decoder func(*Warehouse, string)) int {
    warehouse, err := read_input("input.txt", line_decoder)
    if err != nil {
        panic(err)
    }

    for _, move := range warehouse.moves {
        warehouse.do_move(move)
    }

    return warehouse.compute_score()
}

func main() {
    fmt.Printf("task1 = %d\n", do_task(task1_line_decoder))
    fmt.Printf("task2 = %d\n", do_task(task2_line_decoder))
}
