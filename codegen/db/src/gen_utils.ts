export const snakeToCamel = (str: string) =>
str.replace(/([-_][a-z])/g, community => //.toLowerCase()
    community
        .toUpperCase()
        .replace('-', '')
        .replace('_', '')
);

export const uppercaseFirst = (string: string) => string[0].toUpperCase() + string.substring(1);


import fs from "fs";
const path = require('path');

export function clear_files_from_dir(directory: string) {
    let files = fs.readdirSync(directory );
    for (const file of files) {
        if (!file.startsWith(".")) fs.unlinkSync(path.join(directory, file));
    }
}
