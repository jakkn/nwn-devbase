FROM jakkn/nwnx2server

# Symlink compiled sources to nwnserver
WORKDIR /usr/local/src/nwnx2-linux/build/compiled
RUN ln -s $(pwd)/nwnx_odmbc_mysql.so /opt/nwnserver/nwnx_odbc.so \
    && ln -s $(pwd)/nwnx_profiler.so /opt/nwnserver/nwnx_profiler.so

# Copy nwnx2.ini to nwnserver
RUN cp $(pwd)/nwnx2.ini /opt/nwnserver/

# Change YourModuleHere with your module name
WORKDIR /opt/nwnserver
RUN sed -i \
    -e's/Contest Of Champions 0492/Contest Of Champions 0492/g' \
    nwnstartup.sh

#WORKDIR /var/lib/mysql
#COPY databases/default_mysql testserver
WORKDIR /opt/nwnserver
COPY enabledb.pl .
RUN ./enabledb.pl -d mysql
RUN sed -i \
    -e's/^debuglevel=\d/debuglevel=4/g' \
    -e's/^user=username/user=root/g' \
    -e's/^pass=password/pass=password/g' \
    -e's/^db=database/db=testserver/g' \
    nwnx2.ini

RUN mkdir logs.0

# Default entrypoint
CMD ["./nwnstartup.sh"]
