function parseIsoDatetime(dtstr: string) {
    let dt = dtstr.split(/[: T-]/).map(parseFloat);
    return Date.UTC(dt[0], dt[1] - 1, dt[2], dt[3] || 0, dt[4] || 0, dt[5] || 0, 0);
}

export function dateToStr(date: string) {
    let current_time_milliseconds = new Date().getTime();
    let milliseconds = current_time_milliseconds - parseIsoDatetime(date);

    let temp = Math.floor(milliseconds / 1000);
    let years = Math.floor(temp / 31536000);
    if (years) {
        return years + 'y';
    }
    //TODO: Months! Maybe weeks?
    let days = Math.floor((temp %= 31536000) / 86400);
    if (days) {
        return days + 'd';
    }
    let hours = Math.floor((temp %= 86400) / 3600);
    if (hours) {
        return hours + 'h';
    }
    let minutes = Math.floor((temp %= 3600) / 60);
    if (minutes) {
        return minutes + 'm';
    }
    let seconds = temp % 60;
    if (seconds) {
        return seconds + 's';
    }

    return 'now';
}
