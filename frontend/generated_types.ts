// API input and output types
export type UserId = string

export type User = {
    type: "User";
    display_name: string,
    user_id: UserId
}

// API input types


// API output types


// ENDPOINTS

export type CreateUserInput = {
    type: "CreateUserInput";
    display_name: string,
    user_id: UserId
}
export type CreateUserOutput = {
    type: "CreateUserOutput";
    user_id: UserId
}
export type CreateUserResponse = utils.ApiResponse<CreateUserOutput, ResponseError>;
export function create_user (body: CreateUserInput): Promise<CreateUserResponse> { return utils.post(`/users`, body); }

export type UsersQuery = {
    type: "UsersQuery";
    name?: string,
    next?: string,
    prev?: string,
    limit?: number
}
export type UsersOutput = {
    type: "UsersOutput";
    users: User[]
}
export type UsersResponse = utils.ApiResponse<UsersOutput, ResponseError>;
export function users (q: UsersQuery): Promise<UsersResponse> { return utils.get(`/users${utils.stringify_query(q)}`, q); }

export type GetUserQuery = {}
export type GetUserOutput = {
    type: "GetUserOutput";
    user: User
}
export type GetUserResponse = utils.ApiResponse<GetUserOutput, ResponseError>;
export function get_user (user_id: UserId): Promise<GetUserResponse> { return utils.get(`/user/${user_id}`, user_id); }

export type DeleteUserOutput = {}
export type DeleteUserResponse = utils.ApiResponse<DeleteUserOutput, ResponseError>;
export function delete_user (user_id: UserId): Promise<DeleteUserResponse> { return utils.del(`/user/${user_id}`, user_id); }
