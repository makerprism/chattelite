<script lang="ts">
	import { goto } from "$app/navigation";
	import ChatteliteClient from "chattelite-client";
	import type { Conversation, ConversationId } from "chattelite-client/lib/generated/types";
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
Logged in as {JSON.stringify($session)}

<div>
<button on:click={create_conversation}>Create Conversation</button>
</div>

<div>
    Join conversation
    <input bind:value={join_conversation_id} on:keypress={(e) => e.keyCode == 13? join_conversation(join_conversation_id) : null}>
</div>

<h2>Existing Conversations:</h2>
{#each conversations as conversation}
<div>
    <a href={"/conversation/"+conversation.conversation_id}>{conversation.conversation_id}</a>
    {JSON.stringify(conversation)}
</div>
{/each}
{/if}

<style>
    input {
        display:block;
        width:100%;
    }
</style>
