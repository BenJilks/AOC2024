import fs from 'node:fs';

const INPUT_FILE_PATH = 'input.txt';

function read_input(file_path) {
    const input = fs.readFileSync(file_path, { encoding: 'utf8' });
    return input.trim();
}

function decode_blocks(encoded) {
    let decoded = [];
    encoded.split('').forEach((char, index) => {
        const length = parseInt(char);
        if (index % 2 == 0) {
            const file_index = Math.floor(index / 2);
            decoded.push(...new Array(length).fill(file_index));
        } else {
            decoded.push(...new Array(length).fill(null));
        }
    });

    return decoded;
}

function fragment_disk(disk) {
    let first_free_block_index = disk.findIndex(x => x === null);
    let last_item_index = disk.findLastIndex(x => x !== null);

    while (first_free_block_index < last_item_index) {
        disk[first_free_block_index] = disk[last_item_index];
        disk[last_item_index] = null;

        while (disk[first_free_block_index] !== null) {
            first_free_block_index += 1;
        }
        while (disk[last_item_index] === null) {
            last_item_index -= 1;
        }
    }
}

function find_next_free_space(disk, stop_index, target_length) {
    let start_index = null;

    for (let i = 0; i < stop_index; ++i) {
        if (disk[i] === null) {
            if (start_index === null) {
                start_index = i;
            }

            const length = i - start_index + 1;
            if (length >= target_length) {
                return start_index;
            }
        } else {
            start_index = null;
        }
    }

    return null;
}

function compute_file_length(disk, file_end_index) {
    const file_id = disk[file_end_index];

    let length = 0;
    while (disk[file_end_index - length] == file_id) {
        length += 1;
    }

    return length;
}

function fragment_disk_whole_files(disk) {
    const largest_file_id = disk.findLast(x => x !== null);
    let file_end_index = disk.findLastIndex(x => x === largest_file_id);

    for (let file_id = largest_file_id; file_id >= 0; --file_id) {
        while (disk[file_end_index] !== file_id) {
            file_end_index -= 1;
        }

        const length = compute_file_length(disk, file_end_index);
        const free_space = find_next_free_space(disk, file_end_index, length);
        if (free_space !== null) {
            for (let i = 0; i < length; ++i) {
                disk[free_space + i] = file_id;
                disk[file_end_index - i] = null;
            }
        }
    }
}

function compute_checksum(disk) {
    return disk.reduce((acc, x, index) => acc + index * x);
}

function task1() {
    const input = read_input(INPUT_FILE_PATH);
    const disk = decode_blocks(input);
    fragment_disk(disk);
    console.log(`Task1 checksum = ${compute_checksum(disk)}`);
}

function task2() {
    const input = read_input(INPUT_FILE_PATH);
    const disk = decode_blocks(input);
    fragment_disk_whole_files(disk);
    console.log(`Task2 checksum = ${compute_checksum(disk)}`);
}

task1();
task2();
