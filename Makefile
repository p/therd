js_basenames := app builder db phpbb routes/index tools worker scope queue fsdocs-queue

all: package.json gen

# Delete // comments and trailing commas from package.json.in
package.json: package.json.in
	cat package.json.in |sed -e 's,^ *//.*,,' \
		|perl -e 'undef $$/; $$_=<>; s/,([\s\n]*[\]}])/\1/g; print' \
		>package.json

# Empty dir, create
gen:
	mkdir gen

coffee:
	coffee -c -w -o gen src

npm: package.json
	npm install

js_files := $(addprefix gen/,$(js_basenames))
js_files := $(addsuffix .js,$(js_files))

gen/%.js: src/%.coffee
	coffee -c -o `dirname $@` $<

gen-all: gen $(js_files)
