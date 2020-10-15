FROM debian:10-slim as build

RUN apt-get update && \
	apt-get install -y git clang cmake make gcc g++ libmariadbclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev \
			libboost-all-dev mariadb-server p7zip default-libmysqlclient-dev wget nodejs && \
	update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
	update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100 && \
	rm -rf /var/lib/apt/lists/*

ARG trinitycore_branch=master
ARG latest_commit=acde5cc375d6f4aa9a663d1aa272888b6a6b5a1b

WORKDIR /src

RUN git clone -b $trinitycore_branch --depth 1 git://github.com/TrinityCore/TrinityCore.git && \
	cd ./TrinityCore && \
	mkdir build && \
	cd build && \
	cmake ../ && \
	make -j $(nproc) install && \
	mv ../sql /src && \
	rm -rf /src/TrinityCore

ADD get_tdb_release.js /
RUN mkdir ~/TDB && \
	cd ~/TDB && \
	wget `node /get_tdb_release.js path $trinitycore_branch` && \
	7zr x `node /get_tdb_release.js file $trinitycore_branch` && \
	mv *.sql /usr/local/bin && \
	cd / && \
	rm -rf ~/TDB && \
	rm -f /get_tdb_release.js

FROM debian:10-slim

RUN apt-get update && \
	apt-get install -yqq libssl1.1 libmariadb3 libncurses6 libreadline7 libboost-system1.67.0 libboost-filesystem1.67.0 libboost-thread1.67.0 \
	libboost-program-options1.67.0 libboost-iostreams1.67.0 libboost-regex1.67.0 libboost-chrono1.67.0 libboost-date-time1.67.0
	rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/etc /usr/local/etc
COPY --from=build /src/sql/create/create_mysql.sql /src/sql/create/create_mysql.sql

VOLUME /data
VOLUME /usr/local/etc
VOLUME /logs

ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
