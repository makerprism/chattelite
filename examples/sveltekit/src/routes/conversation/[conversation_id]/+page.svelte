<script lang="ts">
    import ChatteliteClient, { type ConversationEventSource } from "chattelite-client";
	import type { ConversationId, Line, UserId } from "chattelite-client/lib/generated/types";
	import { session } from "./../../../session";
	import { onDestroy, onMount } from "svelte";
	import { dateToStr } from "../../../human-readable-datetime";
	import { goto } from "$app/navigation";

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

    let event_source: ConversationEventSource | null = null;

    async function connect_to_conversation(conversation_id: ConversationId) {
        let conversation = await ChatteliteClient.get_conversation_messages(conversation_id);

        if ("error" in conversation) {
            throw "failed to fetch conversation"
        }

        lines = conversation.lines;

        event_source = ChatteliteClient.listen_to_conversation(conversation_id);
        event_source.onmessage = (e: MessageEvent<string>) => {
            let conversation_event = JSON.parse(e.data);
            console.log("event_source.onmessage", conversation_event);
            switch(conversation_event.type) {
                case "NewLine":
                    lines = [...lines, conversation_event.line];
                    break;
                case "Join":
                    alert(conversation_event.from.id+" joins the conversation");
                    break;
                case "Leave":
                    alert(conversation_event.from.id+" leaves the conversation");
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
            connect_to_conversation(data.conversation_id)
        } else {
            throw "$session is null"
        }
    });

    onDestroy(() => {
        if (event_source) event_source.close();
    });


    let message_input_el: HTMLInputElement;
    let reply_to_line: Line | null = null;
    let new_message = "";

    async function send_message() {
        ChatteliteClient.send_message(data.conversation_id, {
            message: new_message,
            data: {},
            reply_to_line_id: reply_to_line?.line_id || null,
        }).then((r) => {
            if("error" in r) {
                alert("failed to send message!") 
            } else {
                new_message = "";
                reply_to_line = null;
            }
        })
    }

    let chat_window_el: HTMLDivElement;

    let start_typing: number | null;
    let stop_typing: number | null;

    async function input() {
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
        if (n > 1) {
            return `${typing_people.slice(0, n-1).join(", ")}${n > 2 ? ",":""} and ${typing_people[n-1]} are typing...`
        } else if (n == 1) {
            return `${typing_people[0]} is typing...`
        }
        return "";
    }

    function mark_read() {
        console.log("mark_read");
        ChatteliteClient.mark_read({
            conversation_id: data.conversation_id,
            line_id: lines.slice(-1)[0].line_id,
        });
    }

    async function leave_conversation() {
        if ($session) {
            let r = await fetch("/leave-conversation", { method: 'POST', body: JSON.stringify({
                user_ids: [$session.user_id],
                conversation_id: data.conversation_id,
            })});
            if (r.status != 200) throw "failed to join conversation!";

            //let data = await r.json();

            goto("/");
        }
    }
</script>

<h2>{data.conversation_id}</h2>
<div class="chat-window" bind:this={chat_window_el} use:scrollToBottom={lines}>
    <div class="lines">
    {#each lines as line (line.line_id)}
        {#if line.from == null}
        <div class="system-message">
            <span title={new Date(line.timestamp).toLocaleString()} class="timestamp">
                {dateToStr(line.timestamp)}
            </span>
            {line.message}
        </div>
        {:else}
        <div class:my-message={$session?.user_id == line.from.id} class:other-message={$session?.user_id != line.from.id}>
            <span class="display_name">
                {line.from.display_name}
            </span>
            <span title={new Date(line.timestamp).toLocaleString()} class="timestamp">
                {dateToStr(line.timestamp)} &nbsp;
            </span>
            <br>
            <div class="chat-bubble">
                {#if line.reply_to_line }
                <blockquote class="reply_to_line">
                    {line.reply_to_line.message}
                </blockquote>
                {/if}
                {line.message}
            </div>
            <button on:click={() => {reply_to_line = line; message_input_el.focus()}}>reply</button>
        </div>
        {/if}
    {/each}
    </div>
</div>
<div class="typing">
    {render_typing(typing)} &nbsp;
</div>
<input bind:this={message_input_el} bind:value={new_message} on:input={input} on:keypress={(e) => e.keyCode == 13? send_message() : null}>

<button on:click={mark_read}>mark everything read</button>
<button on:click={leave_conversation}>leave conversation</button>

{#if reply_to_line != null}
Replying to {reply_to_line.from.display_name}.
<button on:click={() => reply_to_line = null}>Cancel reply</button>
{/if}

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
        overflow: hidden;
    }

    .display_name {
        font-weight:bold;
    }
    .timestamp {
        color:gray;
        font-size:75%;
    }

    .chat-bubble {
        max-width:55vw;
        display:inline-block;
        overflow: hidden;
        word-wrap: break-word;
        white-space:normal;
        border-radius: 0.5em;

        padding: 0.5em 0.75em;
    }

    .reply_to_line {
        border-left: 0.3em solid #444;
        padding: 0.2em 0.5em;
        background-color: white;
        color:#444;
        white-space:nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .my-message {
        margin-left: auto;
        text-align: right;
    }

    .my-message .display_name {
        float:right;
    }

    .my-message .chat-bubble {
        border-top-right-radius: 0;
        background-color:rgb(45, 91, 59);
        color: #eee;
    }

    .other-message .chat-bubble {
        border-top-left-radius: 0;
        background-color:rgb(199, 224, 207);
        color: #333;
    }


    .typing {
        color:#333;
    }

    input {
        display:block;
        width:100%;
    }
</style>
