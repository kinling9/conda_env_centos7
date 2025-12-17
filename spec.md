# Propose

Using docker and conda-forge to create conda env for glibc 2.17 and incremental
backup using @pack_incremental.sh

## TODO

finish Dockerfile which can create conda env for glibc 2.17

the new package is installed by docker atach

write a script to copy pack result to host machine.

make sure the snar backup file is located on host machine. the docker machine
may recover conda env from snar file located on host machine.
