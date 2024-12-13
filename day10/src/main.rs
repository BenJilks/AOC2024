use std::collections::HashSet;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[derive(Default)]
struct Grid {
    pub width: usize,
    pub height: usize,
    data: Vec<i32>,
}

impl Grid {
    pub fn at(&self, position: &(usize, usize)) -> i32 {
        self.data[position.1 * self.width + position.0]
    }

    pub fn find_trailheads(&self) -> Vec<(usize, usize)> {
        self.data
            .iter()
            .enumerate()
            .filter_map(|(i, altitude)| {
                if *altitude == 0 {
                    Some((i % self.width, i / self.width))
                } else {
                    None
                }
            })
            .collect()
    }

    fn compute_accessible_peaks(&self, start: &(usize, usize)) -> HashSet<(usize, usize)> {
        let current_altitude = self.at(start);
        if current_altitude == 9 {
            return HashSet::from([start.clone()]);
        }

        let mut peaks = HashSet::new();
        for (x_offset, y_offset) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            let x = start.0 as i32 + x_offset;
            if x < 0 || x >= self.width as i32 {
                continue;
            }

            let y = start.1 as i32 + y_offset;
            if y < 0 || y >= self.height as i32 {
                continue;
            }

            let position = (x as usize, y as usize);
            if self.at(&position) == current_altitude + 1 {
                peaks.extend(self.compute_accessible_peaks(&position));
            }
        }

        peaks
    }

    fn compute_distinct_trails(&self, start: &(usize, usize)) -> usize {
        let current_altitude = self.at(start);
        if current_altitude == 9 {
            return 1;
        }

        let mut distinct_trails = 0;
        for (x_offset, y_offset) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            let x = start.0 as i32 + x_offset;
            if x < 0 || x >= self.width as i32 {
                continue;
            }

            let y = start.1 as i32 + y_offset;
            if y < 0 || y >= self.height as i32 {
                continue;
            }

            let position = (x as usize, y as usize);
            if self.at(&position) == current_altitude + 1 {
                distinct_trails += self.compute_distinct_trails(&position);
            }
        }

        distinct_trails
    }
}

fn read_input(file_path: &str) -> std::io::Result<Grid> {
    let file = File::open(file_path)?;
    let mut reader = BufReader::new(file);

    let mut line_buf = String::new();
    let mut grid = Grid::default();
    while reader.read_line(&mut line_buf)? > 0 {
        let line = line_buf.trim();
        for char in line.chars() {
            let altitude = char as i32 - '0' as i32;
            grid.data.push(altitude);
        }

        grid.width = line.len();
        grid.height += 1;
        line_buf.clear();
    }

    Ok(grid)
}

fn main() {
    let grid = read_input("input.txt").expect("Couldn't read input");
    let trailheads = grid.find_trailheads();

    let task1_total_score = trailheads
        .iter()
        .map(|trailhead| grid.compute_accessible_peaks(&trailhead).len())
        .sum::<usize>();
    println!("Task1 = {task1_total_score}");

    let task2_total_score = trailheads
        .iter()
        .map(|trailhead| grid.compute_distinct_trails(&trailhead))
        .sum::<usize>();
    println!("Task2 = {task2_total_score}");
}
