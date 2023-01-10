all: build


db-codegen:
	cd codegen/db && npm install && npm run build && cd ../..

api-codegen:
	cd codegen/api && npm install && npm run build && cd ../..

backend: api-codegen db-codegen
	cd backend/api && cargo build --release && cd ../..

typescript-sdks: api-codegen
	cd sdks/TypeScript/app && npm install && npm run build && cd ../../..
	cd sdks/TypeScript/client && npm install && npm run build && cd ../../..

go-sdks: api-codegen

build: backend typescript-sdks go-sdks

package: backend
	mkdir -p build/deb/chattelite_0.1.0-1_amd64/DEBIAN
	cp -r deb/* build/deb/chattelite_0.1.0-1_amd64/
	mkdir -p build/deb/chattelite_0.1.0-1_amd64/usr/bin
	cp backend/api/target/release/chattelite-server build/deb/chattelite_0.1.0-1_amd64/usr/bin
	cd build/deb && dpkg-deb --build --root-owner-group chattelite_0.1.0-1_amd64 && cd ../..
