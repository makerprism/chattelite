"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.remove_users_from_conversation = exports.add_users_to_conversation = exports.create_conversation = exports.generate_client_jwt = exports.delete_user = exports.create_user = void 0;
const utils = __importStar(require("@utils"));
function create_user(opts, body) {
    return utils.post(`/users`, opts, body);
}
exports.create_user = create_user;
function delete_user(opts, username) {
    return utils.del(`/user/${username}`, opts);
}
exports.delete_user = delete_user;
function generate_client_jwt(opts, body) {
    return utils.post(`/gen-client-jwt`, opts, body);
}
exports.generate_client_jwt = generate_client_jwt;
function create_conversation(opts, body) {
    return utils.post(`/conversations`, opts, body);
}
exports.create_conversation = create_conversation;
function add_users_to_conversation(opts, conversation_id, body) {
    return utils.post(`/conversation/${conversation_id}/add-users`, opts, body);
}
exports.add_users_to_conversation = add_users_to_conversation;
function remove_users_from_conversation(opts, conversation_id, body) {
    return utils.post(`/conversation/${conversation_id}/remove-users`, opts, body);
}
exports.remove_users_from_conversation = remove_users_from_conversation;
