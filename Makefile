all: build


db-codegen:
	cd codegen/db && npm install && npm run build && cd ../..

api-codegen:
	cd codegen/api && npm install && npm run build && cd ../..

backend: api-codegen db-codegen
	cd backend/api && cargo build --release && cd ../..

typescript-sdks: api-codegen
	cd sdks/TypeScript/lib/event-source-with-headers && npm install && npm run build && cd ../../../..
	cd sdks/TypeScript/server && npm install && npm run build && cd ../../..
	cd sdks/TypeScript/client && npm install && npm run build && cd ../../..

go-sdks: api-codegen

build: backend typescript-sdks go-sdks

deb-package: backend
	scripts/build-deb-package.sh
