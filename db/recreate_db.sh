PGPASSWORD=test psql -h 172.17.0.2 -p 5432 -d postgres -U postgres -c 'DROP DATABASE rust_simple_chat'
PGPASSWORD=test psql -h 172.17.0.2 -p 5432 -d postgres -U postgres -c 'CREATE DATABASE rust_simple_chat'
npm run build
