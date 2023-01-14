import { writable, type Writable } from "svelte/store";

export const session: Writable<{
    user_id: string,
    display_name: string,
    jwt: string,
} | null> = writable(null);
