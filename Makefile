NOIR_SRC = $(shell find src -name '*.cr')
ETNOIR_SRC = $(shell find etnoir/src -name '*.cr')

etnoir: bin/etnoir

bin/etnoir: etnoir/bin/etnoir
	ln -sf ../etnoir/bin/etnoir bin/etnoir

etnoir/bin/etnoir: $(NOIR_SRC) $(ETNOIR_SRC)
	cd etnoir && shards update && shards build

spec: noir_spec etnoir_spec

noir_spec:
	crystal spec

etnoir_spec:
	cd etnoir && crystal spec

update_fixture:
	UPDATE_FIXTURE=1 crystal spec

clean:
	rm -rf etnoir/bin/etnoir

.PHONY: etnoir spec noir_spec etnoir_spec clean
