import { error, json, type RequestHandler } from '@sveltejs/kit';
import Chattelite from 'chattelite';

export const POST: RequestHandler = async ({ request }) => {
    let data = await request.json();

    let conversation = await Chattelite.add_users_to_conversation(data.conversation_id, { user_ids: data.user_ids });

    if ("error" in conversation) {
        console.log(conversation);
        throw "failed to join conversation"
    }

    return json({});
}
