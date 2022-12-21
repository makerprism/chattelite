import { TypeName } from "gen-types";

export type IdType = {
    tag: "id_type",
    name: string,
    prefix: string,
};

export function IdType(name: string | TypeName, prefix: string): IdType {
    return {
        tag: "id_type",
        name: (typeof name === "string" ? name : name.name),
        prefix,
    };
}

export const ID_TYPE_DECLARATIONS = `
pub fn from_id_type(id: &str, prefix: &'static str) -> Result<i64, String> {
    let mut buf: [u8;8] = [0, 0, 0, 0, 0, 0, 0, 0];

    base64::decode_config_slice(id.trim_start_matches(&format!("{}-", prefix)), base64::URL_SAFE_NO_PAD, &mut buf)
        .map_err(|_| "failed to deserialize id".to_string())?;
    Ok(i64::from_be_bytes(buf))
}

pub fn id_type(id: &i64, prefix: &'static str) -> String {
    format!("{}-{}", prefix, base64::encode_config((*id).to_be_bytes(), base64::URL_SAFE_NO_PAD))
}`;
