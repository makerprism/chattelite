<script lang="ts">
    import ChatteliteClient from "chattelite-client";
	import type { ConversationEvent, ConversationId, Line, UserId } from "chattelite-client/lib/generated/types";
	import { session } from "./../../../session";
	import { onMount } from "svelte";

    export let data: {
        conversation_id: ConversationId;
    };

    let lines: Line[] = [];
    type Typing = {
        [user_id: UserId]: {
            typing: boolean;
            display_name:string
        }
    };
    let typing: Typing = {};
    let event_source = null;

    async function connect_to_conversation(jwt: string, conversation_id: ConversationId) {
        let conversation = await ChatteliteClient.get_conversation(conversation_id);

        if ("error" in conversation) {
            throw "failed to fetch conversation"
        }

        lines = conversation.lines;

        event_source = new ChatteliteClient.EventSourceWithHeaders("http://127.0.0.1:8000/conversation/" + conversation_id + "/sse", { headers: { "X-Access-Token": jwt } });
        event_source.onmessage = (e: MessageEvent<string>) => {
            let conversation_event = JSON.parse(e.data);
            console.log("event_source.onmessage", conversation_event);
            switch(conversation_event.type) {
                case "NewLine":
                    lines = [...lines, conversation_event.line];
                    break;
                case "StartTyping":
                    typing[conversation_event.from.id] = {
                        display_name: conversation_event.from.display_name,
                        typing: true
                    };
                    break;
                case "EndTyping":
                    typing[conversation_event.from.id] = {
                        display_name: conversation_event.from.display_name,
                        typing: false
                    };
                    break;
            }
        }
    }

    onMount(async () => {
        if ($session) {
            connect_to_conversation($session.jwt, data.conversation_id)
        } else {
            throw "$session is null"
        }
    });



    let new_message = "";

    async function send_message() {
        ChatteliteClient.send_message(data.conversation_id, {
            content: new_message
        }).then((r) => {
            if("error" in r) {
                alert("failed to send message!") 
            } else {
                new_message = "";
            }
        })
    }

    let chat_window_el: HTMLDivElement;

    let start_typing;
    let stop_typing;

    async function input(e) {
        if (!start_typing) {
            ChatteliteClient.start_typing(data.conversation_id, {});
            start_typing = setTimeout(_ => start_typing = null, 2000);
        }
        if (stop_typing) clearTimeout(stop_typing);
        stop_typing = setTimeout(_ => {
            ChatteliteClient.stop_typing(data.conversation_id, {});
        }, 1000);
    }

    const scrollToBottom = (node: HTMLElement, _depends:any) => {
        const scroll = () => node.scroll({
            top: node.scrollHeight,
            behavior: 'smooth',
        });
        scroll();

        return { update: scroll }
    };

    function render_typing(typing: Typing): string {
        let typing_people = [];
        for (let user_id of Object.keys(typing)) {
            if (typing[user_id].typing && $session?.user_id != user_id) {
                typing_people.push(typing[user_id].display_name);
            }
        }
        let n = typing_people.length;
        if (n > 2) {
            return `${n} people are typing...`
        } else if (n == 1) {
            return `${typing_people[0]} is typing...`
        }
        return "";
    }
</script>

<h2>{data.conversation_id}</h2>
<div class="chat-window" bind:this={chat_window_el} use:scrollToBottom={lines}>
    <div class="lines">
    {#each lines as line (line.line_id)}
        {#if line.type == "Message"}
        <div class:my-message={$session?.user_id == line.from.id} class:other-message={$session?.user_id != line.from.id}>
            <span class="display_name">
                {line.from.display_name}
            </span>
            <span class="timestamp">
                {line.timestamp} &nbsp;
            </span>
            <br>
            <div class="message">
                {line.content}
            </div>
        </div>
        {:else if line.type == "Join"}
        <div class="system-message">
            <span class="timestamp">
                {line.timestamp}
            </span>
            <span class="display_name">
                {line.from.display_name}
            </span> joins.
        </div>
        {:else if line.type == "Leave"}
        <div class="system-message">
            <span class="timestamp">
                {line.timestamp}
            </span>
            <span class="display_name">
                {line.from.display_name}
            </span> leaves.
        </div>
        {/if}
    {/each}
    </div>
</div>
<div class="typing">
    {render_typing(typing)} &nbsp;
</div>
<input bind:value={new_message} on:input={input} on:keypress={(e) => e.keyCode == 13? send_message() : null}>

<style>
    .chat-window {
        height:80vh;
        overflow-y: auto;
        background: #eee;
        padding:1em;
        box-sizing: border-box;
    }

    .system-message {
        margin: 0 auto;
        text-align: center;
    }

    .lines {
        display:grid;
        gap:1em;
    }

    .display_name {
        font-weight:bold;
    }
    .timestamp {
        color:gray;
        font-size:75%;
    }

    .message {
        border-radius: 0.5em;
        display:inline-block;

        padding: 0.5em 0.75em;
    }

    .other-message {
        margin-left: auto;
        text-align: right;
    }

    .my-message .message {
        border-top-left-radius: 0;

        background-color:rgb(45, 91, 59);
        color: #eee;
    }

    .other-message .message {
        border-top-right-radius: 0;
        background-color:rgb(199, 224, 207);
        color: #333;
    }

    .other-message .display_name {
        float:right;
    }

    .typing {
        color:#333;
    }

    input {
        display:block;
        width:100%;
    }
</style>
