import * as T from "./types";
import * as utils from "../utils";
export type CreateUserResponse = utils.ApiResponse<{}, void>;
export declare function create_user(opts: {
    session_token: string;
}, body: T.CreateUserInput): Promise<CreateUserResponse>;
export type DeleteUserResponse = utils.ApiResponse<{}, void>;
export declare function delete_user(opts: {
    session_token: string;
}, user_id: String): Promise<DeleteUserResponse>;
export type GenerateClientJwtResponse = utils.ApiResponse<T.GenerateClientJwtOutput, void>;
export declare function generate_client_jwt(opts: {
    session_token: string;
}, body: T.GenerateClientJwtInput): Promise<GenerateClientJwtResponse>;
export type CreateConversationResponse = utils.ApiResponse<T.CreateConversationOutput, void>;
export declare function create_conversation(opts: {
    session_token: string;
}, body: T.CreateConversationInput): Promise<CreateConversationResponse>;
export type AddUsersToConversationResponse = utils.ApiResponse<{}, void>;
export declare function add_users_to_conversation(opts: {
    session_token: string;
}, conversation_id: T.ConversationId, body: T.AddUsersToConversationInput): Promise<AddUsersToConversationResponse>;
export type RemoveUsersFromConversationResponse = utils.ApiResponse<{}, void>;
export declare function remove_users_from_conversation(opts: {
    session_token: string;
}, conversation_id: T.ConversationId, body: T.RemoveUsersFromConversationInput): Promise<RemoveUsersFromConversationResponse>;
