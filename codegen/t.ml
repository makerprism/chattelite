open Gen_types.Types

module T = struct
  let date_time = t "DateTime"
  let user_id = t "UserId"
  let conversation_id = t "ConversationId"
  let line_id = t "LineId"
end

module It = struct end

module Ot = struct
  let user = t "User"
  let paginated_users = t "PaginatedUsers"
  let conversation = t "Conversation"
  let paginated_conversations = t "PaginatedConversations"
  let parent_line = t "ParentLine"
  let line = t "Line"
  let thread = t "Thread"
  let conversation_event = t "ConversationEvent"
end
