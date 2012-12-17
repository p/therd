# Delete // comments and trailing commas from package.json.in
package.json: package.json.in
	cat package.json.in |sed -e 's,^ *//.*,,' \
		|perl -e 'undef $$/; $$_=<>; s/,([\s\n]*[\]}])/\1/; print' \
		>package.json

all: package.json