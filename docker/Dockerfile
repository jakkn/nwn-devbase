FROM jakkn/nwnx2server

# Change YourModuleHere with your module name
WORKDIR /opt/nwnserver
RUN sed -i \
    -e's/Contest Of Champions 0492/YourModuleHere/g' \
    nwnstartup.sh

# Default entrypoint
CMD ["./nwnstartup.sh"]
