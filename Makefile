all: build


db-codegen:
	cd codegen/db && npm install && npm run build && cd ../..

api-codegen:
	cd codegen/api && npm install && npm run build && cd ../..

backend: api-codegen db-codegen
	cd backend/api && cargo build && cd ../..

typescript-sdks: api-codegen
	cd sdks/TypeScript/app && npm install && npm run build && cd ../../..
	cd sdks/TypeScript/client && npm install && npm run build && cd ../../..

go-sdks: api-codegen

build: backend typescript-sdks go-sdks

