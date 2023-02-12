<script lang="ts">
	import { goto } from "$app/navigation";
	import ChatteliteClient from "chattelite-client";
	import type { Conversation, ConversationId } from "chattelite-client/lib/generated/types";
	import { dateToStr } from "../human-readable-datetime";
	import { onMount } from "svelte";
	import { session } from "../session";

    /*export let data: {
        conversation_id: ConversationId;
    };*/

    let username = "";
    let conversations: Conversation[] = [];

    onMount(get_conversations)

    function get_conversations() {
        if ($session) {
            ChatteliteClient.get_conversations().then((r) => {
                if ("error" in r) throw "failed to fetch conversations!"

                conversations = r.conversations;
            })
        }
    }

    function set_username() {
        console.log("set_username", username);
     
        fetch("/login", { method: 'POST', body: JSON.stringify({
            user_id: username
        })}).then(async (r) => {
            if (r.status != 200) throw "failed to log in!";

            let data = await r.json();
            console.log("login response data", data)
            $session = data;
            ChatteliteClient.init({
                api_url: "http://127.0.0.1:8000",
                jwt: data.jwt,
            });

            get_conversations();
        })
    }

    async function create_conversation() {
        if ($session) {
            let r = await fetch("/create-conversation", { method: 'POST', body: JSON.stringify({
                user_ids: [$session.user_id]
            })});
            if (r.status != 200) throw "failed to create conversation!";

            let data = await r.json();

            goto("/conversation/"+data.conversation_id);
        }
    }


    let join_conversation_id = "";
    async function join_conversation(conversation_id: string) {
        if ($session) {
            let r = await fetch("/join-conversation", { method: 'POST', body: JSON.stringify({
                user_ids: [$session.user_id],
                conversation_id,
            })});
            if (r.status != 200) throw "failed to join conversation!";

            let data = await r.json();

            goto("/conversation/"+conversation_id);
        }
    }
</script>

{#if $session == null}
<label>
Username: <input bind:value={username} on:keypress={(e) => e.keyCode == 13? set_username() : null}>
</label>
{:else}
Logged in as {$session.display_name}#{$session.user_id}

<div>
<button on:click={create_conversation}>Create Conversation</button>
</div>

<div>
    Join conversation
    <input bind:value={join_conversation_id} on:keypress={(e) => e.keyCode == 13? join_conversation(join_conversation_id) : null}>
</div>

<h2>Existing Conversations:</h2>
<div class="conversations">
{#each conversations as conversation}
<a href={"/conversation/"+conversation.conversation_id}>
<div class="conversation">
    {conversation.conversation_id}
    <span class="timestamp">{dateToStr(conversation.timestamp)}</span> {#if conversation.number_of_unread_messages}<span class="unread">{conversation.number_of_unread_messages}</span>{/if}
    <div>
        {#if conversation.newest_line}
        {conversation.newest_line?.from.display_name}#{conversation.newest_line?.from.id}: {conversation.newest_line?.message}
        {:else }
        No messages yet.
        {/if}
    </div>
</div>
</a>
{/each}
</div>
{/if}

<style>
    input {
        display:block;
        width:100%;
    }

    .conversations {
        display:flex;
        flex-direction: column;
    }

    a {
        text-decoration: none;
    }

    .conversation {
        padding: 1em;
        color:#333;

        border-top: 1px solid gray;
        word-break: break-word;
    }

    .timestamp {
        color: gray;
        font-size:75%;
    }

    .unread {
        border-radius: 0.5em;
        font-size:75%;
        background-color: red;
        font-weight:bold;
        padding: 0em 0.5em;
        padding-top:0.2em;
        color:white;
    }
</style>
