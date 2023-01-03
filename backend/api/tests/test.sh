curl -X POST http://127.0.0.1:8000/users -H "X-Access-Token: 53whn530h8n530hietpg3oq5pmupq35mupi356mu" -H "Content-Type: application/json" -d '{ "user_id": "test" }'
curl -X POST http://127.0.0.1:8000/users -H "X-Access-Token: 53whn530h8n530hietpg3oq5pmupq35mupi356mu" -H "Content-Type: application/json" -d '{ "user_id": "test2" }'
curl -X POST http://127.0.0.1:8000/conversations -H "X-Access-Token: 53whn530h8n530hietpg3oq5pmupq35mupi356mu" -H "Content-Type: application/json" -d '{ "users": [] }'
curl -X POST http://127.0.0.1:8000/conversation/CON-AAAAAAAAAAI/add-users -H "X-Access-Token: 53whn530h8n530hietpg3oq5pmupq35mupi356mu" -H "Content-Type: application/json" -d '{ "users": ["test", "test2"] }'

curl -X POST http://127.0.0.1:8000/gen-client-jwt -H "X-Access-Token: 53whn530h8n530hietpg3oq5pmupq35mupi356mu" -H "Content-Type: application/json" -d '{ "user_id": "test" }'
curl -X POST http://127.0.0.1:8000/conversation/CON-AAAAAAAAAAI -H "X-Access-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2NzI2Nzc4NjYsImNvbnRlbnQiOnsiYWNjb3VudF9pZCI6MSwidXNlcm5hbWUiOiJ0ZXN0In19.PWGnd5dpGwSdYeseEtypHxJ2FzxGbQ7MPMFIk7nLCpg" -H "Content-Type: application/json" -d '{ "content": "hallo" }'
curl -X GET http://127.0.0.1:8000/conversation/CON-AAAAAAAAAAI/events -H "X-Access-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE2NzI2NTI2MDAsImNvbnRlbnQiOnsiYWNjb3VudF9pZCI6MSwidXNlcm5hbWUiOiJ0ZXN0In19.Xcp8NynmmqRGL9vK-Sp37VjZKFsGCV7YLz6B6iEbKfo" -H "Content-Type: application/json"
