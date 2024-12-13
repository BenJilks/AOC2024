#include <cwchar>
#include <iostream>
#include <fstream>
#include <vector>
#include <optional>
#include <unordered_map>

typedef size_t RegionID;
typedef size_t SideID;

struct Point {
    int x;
    int y;
};

enum class Direction {
    Up,
    Down,
    Left,
    Right,
};

struct Farm {
    size_t width { 0 };
    size_t height { 0 };
    std::vector<char> plots;
    std::vector<std::optional<RegionID>> region_map;

    bool in_bounds(Point const& point) const {
        return point.x >= 0 && point.x < width
            && point.y >= 0 && point.y < height;
    }
};

struct Region {
    size_t area { 0 };
    size_t perimeter { 0 };
    size_t sides { 0 };
};

template<typename Callback>
void for_each_neighbour(int x, int y, Callback callback) {
    callback({x, y - 1}, Direction::Up);
    callback({x, y + 1}, Direction::Down);
    callback({x - 1, y}, Direction::Left);
    callback({x + 1, y}, Direction::Right);
}

void fill_island(Farm& farm, RegionID region_id, int x, int y) {
    auto index = y * farm.width + x;
    char plot = farm.plots[index];
    farm.region_map[index] = region_id;

    for_each_neighbour(x, y, [&](Point neighbour, Direction) {
        if (!farm.in_bounds(neighbour)) {
            return;
        }

        auto index = neighbour.y * farm.width + neighbour.x;
        if (!farm.region_map[index].has_value() && farm.plots[index] == plot) {
            fill_island(farm, region_id, neighbour.x, neighbour.y);
        }
    });
}

void find_regions(Farm& farm) {
    RegionID current_region_id = 0;
    farm.region_map.resize(farm.width * farm.height);

    for (size_t y = 0; y < farm.height; ++y) {
        for (size_t x = 0; x < farm.width; ++x) {
            if (farm.region_map[y * farm.height + x].has_value()) {
                continue;
            }

            fill_island(farm, current_region_id, x, y);
            current_region_id += 1;
        }
    }
}

Farm read_input(char const* input_file_path) {
    Farm farm;

    std::fstream stream(input_file_path);
    std::string line;
    while (stream >> line) {
        farm.plots.insert(farm.plots.end(), line.begin(), line.end());
        farm.width = line.length();
        farm.height += 1;
    }

    find_regions(farm);
    return farm;
}

bool is_edge(Farm const& farm, Point const& neighbour, RegionID region_id) {
    if (!farm.in_bounds(neighbour)) {
        return true;
    }

    auto index = neighbour.y * farm.width + neighbour.x;
    auto neighbour_region_id = *farm.region_map[index];
    return neighbour_region_id != region_id;
}

std::unordered_map<RegionID, Region> compute_region_metrics(Farm const& farm) {
    std::unordered_map<RegionID, Region> regions;
    std::vector<std::optional<RegionID>> current_left_fences(farm.width);
    std::vector<std::optional<RegionID>> current_right_fences(farm.width);

    for (int y = 0; y < farm.height; ++y) {
        std::optional<RegionID> current_top_fence;
        std::optional<RegionID> current_bottom_fence;

        for (int x = 0; x < farm.width; ++x) {
            auto region_id = *farm.region_map[y * farm.width + x];
            if (!regions.contains(region_id)) {
                regions[region_id] = {};
            }

            auto& region = regions.at(region_id);
            region.area += 1;

            for_each_neighbour(x, y, [&](Point neighbour, Direction direction) {
                if (is_edge(farm, neighbour, region_id)) {
                    region.perimeter += 1;

                    switch (direction) {
                        case Direction::Up:
                            if (current_top_fence != region_id) { region.sides += 1; }
                            current_top_fence = region_id;
                            break;
                        case Direction::Down:
                            if (current_bottom_fence != region_id) { region.sides += 1; }
                            current_bottom_fence = region_id;
                            break;
                        case Direction::Left:
                            if (current_left_fences[x] != region_id) { region.sides += 1; }
                            current_left_fences[x] = region_id;
                            break;
                        case Direction::Right:
                            if (current_right_fences[x] != region_id) { region.sides += 1; }
                            current_right_fences[x] = region_id;
                            break;
                        default: break;
                    }
                } else {
                    switch (direction) {
                        case Direction::Up: current_top_fence = std::nullopt; break;
                        case Direction::Down: current_bottom_fence = std::nullopt; break;
                        case Direction::Left: current_left_fences[x] = std::nullopt; break;
                        case Direction::Right: current_right_fences[x] = std::nullopt; break;
                        default: break;
                    }
                }
            });
        }
    }

    return regions;
}

int main() {
    auto const farm = read_input("input.txt");

    size_t task1_total_cost = 0;
    size_t task2_total_cost = 0;
    for (auto const& [region_id, region] : compute_region_metrics(farm)) {
        task1_total_cost += region.area * region.perimeter;
        task2_total_cost += region.area * region.sides;
    }

    std::cout << "task1 = " << task1_total_cost << "\n";
    std::cout << "task2 = " << task2_total_cost << "\n";
    return 0;
}

