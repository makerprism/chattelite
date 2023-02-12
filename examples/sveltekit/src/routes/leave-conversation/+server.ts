import { error, json, type RequestHandler } from '@sveltejs/kit';
import Chattelite from 'chattelite';

export const POST: RequestHandler = async ({ request }) => {
    let data = await request.json();

    let conversation = await Chattelite.remove_users_from_conversation(data.conversation_id, { user_ids: data.user_ids });

    if ("error" in conversation) {
        console.log(conversation);
        throw "failed to join conversation"
    }

    return json({});
}
