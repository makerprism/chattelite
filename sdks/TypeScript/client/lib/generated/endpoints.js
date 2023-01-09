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
exports.mark_read = exports.stop_typing = exports.start_typing = exports.send_message = exports.get_conversation_events = exports.get_connection_events = void 0;
const utils = __importStar(require("../utils"));
function get_connection_events(opts) {
    return utils.get(`/events`, opts);
}
exports.get_connection_events = get_connection_events;
function get_conversation_events(opts, conversation_id) {
    return utils.get(`/conversation/${conversation_id}/events`, opts);
}
exports.get_conversation_events = get_conversation_events;
function send_message(opts, conversation_id, body) {
    return utils.post(`/conversation/${conversation_id}`, opts, body);
}
exports.send_message = send_message;
function start_typing(opts, conversation_id, body) {
    return utils.post(`/conversation/${conversation_id}/start-typing`, opts, body);
}
exports.start_typing = start_typing;
function stop_typing(opts, conversation_id, body) {
    return utils.post(`/conversation/${conversation_id}/stop-typing`, opts, body);
}
exports.stop_typing = stop_typing;
function mark_read(opts, body) {
    return utils.post(`/read`, opts, body);
}
exports.mark_read = mark_read;
