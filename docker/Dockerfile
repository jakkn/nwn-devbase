FROM jakkn/nwnx2server:latest

# set debug level
RUN sed -i \
    -e's/^debuglevel=[0-9]/debuglevel=4/g' \
    nwnx2.ini

# nwnplayer.ini configs
RUN sed -i \
    -e's/^ItemLevelRestrictions=[0-9]/ItemLevelRestrictions=0/g' \
    nwnplayer.ini
