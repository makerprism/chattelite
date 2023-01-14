import { error, json, type RequestHandler } from '@sveltejs/kit';
import Chattelite from 'chattelite';

export const POST: RequestHandler = async ({ request }) => {
    let data = await request.json();

    let conversation = await Chattelite.create_conversation({ user_ids: data.user_ids });

    if ("error" in conversation) {
        throw "failed to create conversation"
    }

    return json({
        conversation_id: conversation.conversation_id, 
    });
}
