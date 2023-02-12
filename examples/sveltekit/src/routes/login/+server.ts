import { error, json, type RequestHandler } from '@sveltejs/kit';
import Chattelite from 'chattelite';

export const POST: RequestHandler = async ({ request }) => {
    let data = await request.json();

    await Chattelite.create_user({
        id: data.user_id,
        display_name: data.user_id,
        data: {},
    });

    let jwt = await Chattelite.generate_client_jwt({ user_id: data.user_id });
    if ("error" in jwt) {
        throw "failed to create client JWT"
    }

    return json({
        user_id: data.user_id,
        display_name: data.user_id,
        ...jwt,
    });
}
