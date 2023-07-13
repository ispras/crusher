SRC := $(wildcard *.c)

.PHONY: all client server clean

all: client server

client: $(SRC)
	@echo "Compile client"
	@gcc -g -no-pie -fno-pie -o ./client ./client.c
	@echo -n "Address of detect const is "
	@readelf -s ./client | grep DETECT | awk '{print $$2}' | awk '{ sub(/^[0]+/, ""); printf "0x"; print }'
	@echo -n "Address of func is "
	@readelf -s ./client | grep get_flags | awk '{print $$2}' | awk '{ sub(/^[0]+/, ""); printf "0x"; print }'
	@echo -n "Address of buffer is "
	@readelf -s ./client | grep buf | awk '{print $$2}' | awk '{ sub(/^[0]+/, ""); printf "0x"; print }'

server: $(SRC)
	@echo "Compile server"
	@gcc -g -no-pie -fno-pie -o ./server ./server.c
	@echo -n "Address of detect const is "
	@readelf -s ./server | grep DETECT | awk '{print $$2}' | awk '{ sub(/^[0]+/, ""); printf "0x"; print }'

clean:
	@echo "Remove all binaries"
	@rm -f ./server ./client
